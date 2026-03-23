-- Kamera hash-chain + export + chain-of-custody
-- V108.1: camera_segment_hash + camera_export_request + chain_of_custody_record

CREATE TABLE camera_segment_hash (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id      UUID NOT NULL,
    branch_id         UUID NOT NULL,
    camera_id         VARCHAR(50) NOT NULL,
    sequence_number   INTEGER NOT NULL,
    file_hash         VARCHAR(64) NOT NULL,
    previous_hash     VARCHAR(64) NOT NULL,
    chain_hash        VARCHAR(64) NOT NULL,
    file_path         VARCHAR(500),
    file_size_bytes   BIGINT,
    created_at        TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT uk_camera_hash_sequence UNIQUE (branch_id, camera_id, sequence_number),
    CONSTRAINT fk_camera_hash_recording FOREIGN KEY (recording_id) REFERENCES camera_recording(id),
    CONSTRAINT fk_camera_hash_branch FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE INDEX idx_camera_hash_branch_camera ON camera_segment_hash(branch_id, camera_id);
CREATE INDEX idx_camera_hash_recording ON camera_segment_hash(recording_id);
CREATE INDEX idx_camera_hash_sequence ON camera_segment_hash(branch_id, camera_id, sequence_number);

CREATE TABLE camera_export_request (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id           UUID NOT NULL,
    camera_id           VARCHAR(50),
    period_from         TIMESTAMP NOT NULL,
    period_to           TIMESTAMP NOT NULL,
    reason              TEXT NOT NULL,
    reference_number    VARCHAR(100),
    status              VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',

    requested_by        VARCHAR(100) NOT NULL,
    created_at          TIMESTAMP DEFAULT now(),

    approved_by         VARCHAR(100),
    approved_at         TIMESTAMP,
    rejection_reason    TEXT,

    export_path         VARCHAR(500),
    export_size_bytes   BIGINT,
    manifest_hash       VARCHAR(64),
    completed_at        TIMESTAMP,
    error_message       TEXT,

    CONSTRAINT fk_camera_export_branch FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE INDEX idx_camera_export_branch ON camera_export_request(branch_id);
CREATE INDEX idx_camera_export_status ON camera_export_request(status);
CREATE INDEX idx_camera_export_created ON camera_export_request(created_at);

CREATE TABLE chain_of_custody_record (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    export_request_id   UUID,
    branch_id           UUID NOT NULL,
    camera_id           VARCHAR(50),
    event_type          VARCHAR(30) NOT NULL,
    actor               VARCHAR(100) NOT NULL,
    event_timestamp     TIMESTAMP NOT NULL DEFAULT now(),
    details             TEXT,
    period_from         TIMESTAMP,
    period_to           TIMESTAMP,
    source_ip           VARCHAR(45),
    manifest_hash       VARCHAR(64),

    CONSTRAINT fk_coc_export FOREIGN KEY (export_request_id) REFERENCES camera_export_request(id),
    CONSTRAINT fk_coc_branch FOREIGN KEY (branch_id) REFERENCES branch(id)
);

CREATE INDEX idx_coc_export ON chain_of_custody_record(export_request_id);
CREATE INDEX idx_coc_branch ON chain_of_custody_record(branch_id);
CREATE INDEX idx_coc_timestamp ON chain_of_custody_record(event_timestamp);
