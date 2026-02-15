import { logger } from '../../utils/logger.js';
import { redis } from '../../services/redis.js';
import { supabase } from '../../services/supabase.js';
import { translateText } from '../../services/ai/translation.service.js';
import { transcribeAudio } from '../../services/ai/stt.service.js';
import { synthesizeSpeech } from '../../services/ai/tts.service.js';

export const handleTranslation = (socket, io) => {
  // Handle audio chunk for transcription
  socket.on('audio_chunk', async (data) => {
    try {
      const { sessionId, audioData, sequence } = data;
      const startTime = Date.now();

      if (socket.sessionId !== sessionId) {
        socket.emit('error', { message: 'Not in this session' });
        return;
      }

      // Notify processing started
      socket.emit('processing_start', { sequence, stage: 'stt' });

      // Get session info
      const sessionData = await redis.get(`session:${sessionId}`);
      if (!sessionData) {
        socket.emit('error', { message: 'Session not found' });
        return;
      }

      const session = JSON.parse(sessionData);
      const sourceLanguage = session.user_a_id === socket.userId ? session.language_a : session.language_b;
      const targetLanguage = session.user_a_id === socket.userId ? session.language_b : session.language_a;
      const partnerId = session.user_a_id === socket.userId ? session.user_b_id : session.user_a_id;

      // Step 1: Speech-to-Text
      const sttStart = Date.now();
      const transcription = await transcribeAudio(audioData, sourceLanguage);
      const sttLatency = Date.now() - sttStart;

      if (!transcription || transcription.trim().length === 0) {
        socket.emit('processing_end', { sequence, message: 'No speech detected' });
        return;
      }

      // Emit transcription to sender
      socket.emit('transcription', {
        sequence,
        text: transcription,
        language: sourceLanguage,
        latency: sttLatency
      });

      // Step 2: Translation
      socket.emit('processing_start', { sequence, stage: 'translation' });
      const translationStart = Date.now();
      const translation = await translateText(transcription, sourceLanguage, targetLanguage);
      const translationLatency = Date.now() - translationStart;

      // Step 3: Text-to-Speech
      socket.emit('processing_start', { sequence, stage: 'tts' });
      const ttsStart = Date.now();
      const audioBuffer = await synthesizeSpeech(translation, targetLanguage);
      const ttsLatency = Date.now() - ttsStart;

      const totalLatency = Date.now() - startTime;

      // Send translation to partner
      const partnerSocketId = await redis.get(`user:${partnerId}:socket`);
      if (partnerSocketId) {
        io.to(partnerSocketId).emit('translation', {
          sequence,
          originalText: transcription,
          translatedText: translation,
          audioData: audioBuffer,
          sourceLanguage,
          targetLanguage,
          latency: {
            stt: sttLatency,
            translation: translationLatency,
            tts: ttsLatency,
            total: totalLatency
          }
        });
      }

      // Send confirmation to sender
      socket.emit('translation_sent', {
        sequence,
        translatedText: translation,
        latency: totalLatency
      });

      // Log translation
      await supabase.from('translation_logs').insert([{
        session_id: sessionId,
        user_id: socket.userId,
        original_text: transcription,
        translated_text: translation,
        source_language: sourceLanguage,
        target_language: targetLanguage,
        stt_latency: sttLatency,
        translation_latency: translationLatency,
        tts_latency: ttsLatency,
        total_latency: totalLatency
      }]);

      // Store in Redis for history (keep last 50 messages)
      await redis.lpush(
        `session:${sessionId}:messages`,
        JSON.stringify({
          userId: socket.userId,
          originalText: transcription,
          translatedText: translation,
          timestamp: Date.now(),
          latency: totalLatency
        })
      );
      await redis.ltrim(`session:${sessionId}:messages`, 0, 49);

      // Update session message count
      await supabase
        .from('sessions')
        .update({ total_messages: session.total_messages + 1 })
        .eq('id', sessionId);

      socket.emit('processing_end', { sequence, success: true });

      logger.info(`Translation completed: ${sessionId}, latency: ${totalLatency}ms`);
    } catch (error) {
      logger.error('Translation error:', error);
      socket.emit('error', {
        message: 'Translation failed',
        details: error.message
      });
      socket.emit('processing_end', { sequence: data.sequence, success: false });
    }
  });

  // Handle text-only translation (for testing or text input)
  socket.on('translate_text', async (data) => {
    try {
      const { sessionId, text, sequence } = data;
      const startTime = Date.now();

      if (socket.sessionId !== sessionId) {
        socket.emit('error', { message: 'Not in this session' });
        return;
      }

      const sessionData = await redis.get(`session:${sessionId}`);
      if (!sessionData) {
        socket.emit('error', { message: 'Session not found' });
        return;
      }

      const session = JSON.parse(sessionData);
      const sourceLanguage = session.user_a_id === socket.userId ? session.language_a : session.language_b;
      const targetLanguage = session.user_a_id === socket.userId ? session.language_b : session.language_a;
      const partnerId = session.user_a_id === socket.userId ? session.user_b_id : session.user_a_id;

      // Translate
      const translation = await translateText(text, sourceLanguage, targetLanguage);
      
      // Generate speech
      const audioBuffer = await synthesizeSpeech(translation, targetLanguage);
      
      const totalLatency = Date.now() - startTime;

      // Send to partner
      const partnerSocketId = await redis.get(`user:${partnerId}:socket`);
      if (partnerSocketId) {
        io.to(partnerSocketId).emit('translation', {
          sequence,
          originalText: text,
          translatedText: translation,
          audioData: audioBuffer,
          sourceLanguage,
          targetLanguage,
          latency: { total: totalLatency }
        });
      }

      socket.emit('translation_sent', {
        sequence,
        translatedText: translation,
        latency: totalLatency
      });

      logger.info(`Text translation completed: ${sessionId}`);
    } catch (error) {
      logger.error('Text translation error:', error);
      socket.emit('error', { message: 'Translation failed' });
    }
  });

  // Get translation history
  socket.on('get_history', async (data) => {
    try {
      const { sessionId, limit = 20 } = data;

      if (socket.sessionId !== sessionId) {
        socket.emit('error', { message: 'Not in this session' });
        return;
      }

      const messages = await redis.lrange(`session:${sessionId}:messages`, 0, limit - 1);
      const history = messages.map(msg => JSON.parse(msg));

      socket.emit('history', { sessionId, messages: history });
    } catch (error) {
      logger.error('Error getting history:', error);
      socket.emit('error', { message: 'Failed to get history' });
    }
  });
};
