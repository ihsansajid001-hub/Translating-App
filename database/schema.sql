-- Real-Time Translation System Database Schema
-- For Supabase PostgreSQL

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (managed by Supabase Auth, but we add custom fields)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    preferred_language VARCHAR(10) DEFAULT 'en',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_sessions INTEGER DEFAULT 0,
    total_translations INTEGER DEFAULT 0
);

-- Create indexes for users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_last_active ON users(last_active);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_code VARCHAR(10) UNIQUE NOT NULL,
    user_a_id UUID REFERENCES users(id) ON DELETE CASCADE,
    user_b_id UUID REFERENCES users(id) ON DELETE CASCADE,
    language_a VARCHAR(10) NOT NULL,
    language_b VARCHAR(10),
    status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'ended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    total_messages INTEGER DEFAULT 0,
    avg_latency INTEGER,
    max_latency INTEGER,
    min_latency INTEGER
);

-- Create indexes for sessions
CREATE INDEX idx_sessions_code ON sessions(session_code);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_user_a ON sessions(user_a_id);
CREATE INDEX idx_sessions_user_b ON sessions(user_b_id);
CREATE INDEX idx_sessions_created_at ON sessions(created_at);

-- Translation logs table
CREATE TABLE IF NOT EXISTS translation_logs (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    source_language VARCHAR(10) NOT NULL,
    target_language VARCHAR(10) NOT NULL,
    stt_latency INTEGER,
    translation_latency INTEGER,
    tts_latency INTEGER,
    total_latency INTEGER,
    confidence_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for translation_logs
CREATE INDEX idx_translation_logs_session ON translation_logs(session_id);
CREATE INDEX idx_translation_logs_user ON translation_logs(user_id);
CREATE INDEX idx_translation_logs_created_at ON translation_logs(created_at);
CREATE INDEX idx_translation_logs_languages ON translation_logs(source_language, target_language);

-- Session metrics table (aggregated statistics)
CREATE TABLE IF NOT EXISTS session_metrics (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    avg_latency INTEGER,
    max_latency INTEGER,
    min_latency INTEGER,
    total_messages INTEGER,
    error_count INTEGER DEFAULT 0,
    duration_seconds INTEGER,
    quality_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for session_metrics
CREATE INDEX idx_session_metrics_session ON session_metrics(session_id);
CREATE INDEX idx_session_metrics_created_at ON session_metrics(created_at);

-- User preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    auto_play_audio BOOLEAN DEFAULT true,
    show_original_text BOOLEAN DEFAULT true,
    voice_speed DECIMAL(2,1) DEFAULT 1.0 CHECK (voice_speed BETWEEN 0.5 AND 2.0),
    preferred_voice VARCHAR(50),
    enable_notifications BOOLEAN DEFAULT true,
    theme VARCHAR(20) DEFAULT 'light' CHECK (theme IN ('light', 'dark', 'auto')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for user_preferences
CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);

-- Feedback table (for quality improvement)
CREATE TABLE IF NOT EXISTS feedback (
    id BIGSERIAL PRIMARY KEY,
    translation_log_id BIGINT REFERENCES translation_logs(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    issue_type VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for feedback
CREATE INDEX idx_feedback_translation ON feedback(translation_log_id);
CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_feedback_created_at ON feedback(created_at);

-- Functions and Triggers

-- Update last_active timestamp
CREATE OR REPLACE FUNCTION update_last_active()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users SET last_active = NOW() WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_active
AFTER INSERT ON translation_logs
FOR EACH ROW
EXECUTE FUNCTION update_last_active();

-- Update user statistics
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Update translation count
        UPDATE users 
        SET total_translations = total_translations + 1 
        WHERE id = NEW.user_id;
        
        -- Update session message count
        UPDATE sessions 
        SET total_messages = total_messages + 1 
        WHERE id = NEW.session_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_stats
AFTER INSERT ON translation_logs
FOR EACH ROW
EXECUTE FUNCTION update_user_stats();

-- Update session statistics
CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE sessions
    SET 
        avg_latency = (
            SELECT AVG(total_latency)::INTEGER 
            FROM translation_logs 
            WHERE session_id = NEW.session_id
        ),
        max_latency = (
            SELECT MAX(total_latency) 
            FROM translation_logs 
            WHERE session_id = NEW.session_id
        ),
        min_latency = (
            SELECT MIN(total_latency) 
            FROM translation_logs 
            WHERE session_id = NEW.session_id
        )
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_stats
AFTER INSERT ON translation_logs
FOR EACH ROW
EXECUTE FUNCTION update_session_stats();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE translation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Users can read their own data
CREATE POLICY users_select_own ON users
    FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own data
CREATE POLICY users_update_own ON users
    FOR UPDATE
    USING (auth.uid() = id);

-- Users can read sessions they're part of
CREATE POLICY sessions_select_own ON sessions
    FOR SELECT
    USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- Users can create sessions
CREATE POLICY sessions_insert_own ON sessions
    FOR INSERT
    WITH CHECK (auth.uid() = user_a_id);

-- Users can update sessions they're part of
CREATE POLICY sessions_update_own ON sessions
    FOR UPDATE
    USING (auth.uid() = user_a_id OR auth.uid() = user_b_id);

-- Users can read translation logs from their sessions
CREATE POLICY translation_logs_select_own ON translation_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM sessions 
            WHERE sessions.id = translation_logs.session_id 
            AND (sessions.user_a_id = auth.uid() OR sessions.user_b_id = auth.uid())
        )
    );

-- Users can insert their own translation logs
CREATE POLICY translation_logs_insert_own ON translation_logs
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can read their own preferences
CREATE POLICY user_preferences_select_own ON user_preferences
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert/update their own preferences
CREATE POLICY user_preferences_insert_own ON user_preferences
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_preferences_update_own ON user_preferences
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can submit feedback for their translations
CREATE POLICY feedback_insert_own ON feedback
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Views for analytics

-- Active sessions view
CREATE OR REPLACE VIEW active_sessions_view AS
SELECT 
    s.*,
    ua.username as user_a_username,
    ub.username as user_b_username,
    EXTRACT(EPOCH FROM (NOW() - s.started_at))::INTEGER as duration_seconds
FROM sessions s
LEFT JOIN users ua ON s.user_a_id = ua.id
LEFT JOIN users ub ON s.user_b_id = ub.id
WHERE s.status = 'active';

-- User statistics view
CREATE OR REPLACE VIEW user_stats_view AS
SELECT 
    u.id,
    u.username,
    u.email,
    u.total_sessions,
    u.total_translations,
    COUNT(DISTINCT s.id) as active_sessions,
    AVG(tl.total_latency)::INTEGER as avg_latency,
    u.last_active
FROM users u
LEFT JOIN sessions s ON (u.id = s.user_a_id OR u.id = s.user_b_id) AND s.status = 'active'
LEFT JOIN translation_logs tl ON u.id = tl.user_id
GROUP BY u.id;

-- Language pair statistics
CREATE OR REPLACE VIEW language_pair_stats AS
SELECT 
    source_language,
    target_language,
    COUNT(*) as translation_count,
    AVG(total_latency)::INTEGER as avg_latency,
    AVG(confidence_score) as avg_confidence
FROM translation_logs
GROUP BY source_language, target_language
ORDER BY translation_count DESC;

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Insert default supported languages (for reference)
CREATE TABLE IF NOT EXISTS supported_languages (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    native_name VARCHAR(50) NOT NULL,
    enabled BOOLEAN DEFAULT true
);

INSERT INTO supported_languages (code, name, native_name) VALUES
('en', 'English', 'English'),
('es', 'Spanish', 'Español'),
('fr', 'French', 'Français'),
('de', 'German', 'Deutsch'),
('it', 'Italian', 'Italiano'),
('pt', 'Portuguese', 'Português'),
('ru', 'Russian', 'Русский'),
('ar', 'Arabic', 'العربية'),
('zh', 'Chinese', '中文'),
('ja', 'Japanese', '日本語'),
('ko', 'Korean', '한국어'),
('hi', 'Hindi', 'हिन्दी'),
('tr', 'Turkish', 'Türkçe'),
('nl', 'Dutch', 'Nederlands'),
('pl', 'Polish', 'Polski'),
('ur', 'Urdu', 'اردو'),
('ps', 'Pashto', 'پښتو'),
('fa', 'Dari', 'دری')
ON CONFLICT (code) DO NOTHING;

-- Create function to clean old data (for free tier limits)
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS void AS $$
BEGIN
    -- Delete translation logs older than 30 days
    DELETE FROM translation_logs 
    WHERE created_at < NOW() - INTERVAL '30 days';
    
    -- Delete ended sessions older than 7 days
    DELETE FROM sessions 
    WHERE status = 'ended' AND ended_at < NOW() - INTERVAL '7 days';
    
    -- Delete old feedback
    DELETE FROM feedback 
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup (run manually or via cron)
-- SELECT cleanup_old_data();
