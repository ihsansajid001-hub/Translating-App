import { config } from '../config/index.js';
import { supabase } from '../services/supabase.js';
import { AppError } from '../middleware/errorHandler.js';

const LANGUAGE_NAMES = {
  en: 'English',
  es: 'Spanish',
  fr: 'French',
  de: 'German',
  it: 'Italian',
  pt: 'Portuguese',
  ru: 'Russian',
  ar: 'Arabic',
  zh: 'Chinese',
  ja: 'Japanese',
  ko: 'Korean',
  hi: 'Hindi',
  tr: 'Turkish',
  nl: 'Dutch',
  pl: 'Polish',
  ur: 'Urdu',
  ps: 'Pashto',
  fa: 'Dari'
};

export const getSupportedLanguages = async (req, res, next) => {
  try {
    const languages = config.supportedLanguages.map(code => ({
      code,
      name: LANGUAGE_NAMES[code] || code,
      nativeName: LANGUAGE_NAMES[code] || code
    }));

    res.json({
      success: true,
      data: languages
    });
  } catch (error) {
    next(error);
  }
};

export const getTranslationStats = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Get user's translation statistics
    const { data, error } = await supabase
      .from('translation_logs')
      .select('*')
      .eq('user_id', userId);

    if (error) throw new AppError(error.message, 400);

    const stats = {
      totalTranslations: data.length,
      averageLatency: data.reduce((sum, t) => sum + (t.total_latency || 0), 0) / data.length || 0,
      languagePairs: [...new Set(data.map(t => `${t.source_language}-${t.target_language}`))].length,
      mostUsedLanguages: getMostUsedLanguages(data)
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

function getMostUsedLanguages(translations) {
  const languageCounts = {};
  
  translations.forEach(t => {
    languageCounts[t.source_language] = (languageCounts[t.source_language] || 0) + 1;
    languageCounts[t.target_language] = (languageCounts[t.target_language] || 0) + 1;
  });

  return Object.entries(languageCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([code, count]) => ({
      code,
      name: LANGUAGE_NAMES[code] || code,
      count
    }));
}
