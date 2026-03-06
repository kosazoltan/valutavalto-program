-- Camera system tables for surveillance recording

CREATE TABLE camera_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    camera_id VARCHAR(50) NOT NULL,
    camera_name VARCHAR(100),
    device_index INTEGER DEFAULT 0,
    resolution_width INTEGER DEFAULT 640,
    resolution_height INTEGER DEFAULT 480,
    fps INTEGER DEFAULT 5,
    jpeg_quality INTEGER DEFAULT 70,
    local_storage_path VARCHAR(500),
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(branch_id, camera_id)
);

CREATE TABLE camera_recording (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branch(id),
    camera_id VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    local_file_path VARCHAR(500),
    server_file_path VARCHAR(500),
    file_size_bytes BIGINT,
    uploaded_to_server BOOLEAN DEFAULT false,
    upload_attempts INTEGER DEFAULT 0,
    expires_at DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'RECORDING',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_camera_recording_branch_date ON camera_recording(branch_id, start_time);
CREATE INDEX idx_camera_recording_expires ON camera_recording(expires_at);
CREATE INDEX idx_camera_recording_upload ON camera_recording(uploaded_to_server) WHERE NOT uploaded_to_server;

CREATE TABLE camera_transaction_link (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID NOT NULL REFERENCES camera_recording(id) ON DELETE CASCADE,
    transaction_id UUID,
    receipt_number VARCHAR(50),
    transaction_time TIMESTAMP NOT NULL,
    frame_offset_seconds INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_camera_tx_link_receipt ON camera_transaction_link(receipt_number);
CREATE INDEX idx_camera_tx_link_tx ON camera_transaction_link(transaction_id);

CREATE TABLE camera_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID REFERENCES camera_recording(id),
    worker_id BIGINT NOT NULL,
    action VARCHAR(30) NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT NOW()
);
