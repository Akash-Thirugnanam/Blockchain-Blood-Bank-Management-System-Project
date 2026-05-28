-- Blockchain Blood Bank Management System - MySQL Database Schema
-- Version 1.0

-- ============================================
-- Users Table (Base for all users)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    zipcode VARCHAR(20),
    role ENUM('admin', 'donor', 'hospital', 'bloodbank') NOT NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    profile_image VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_token VARCHAR(255),
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_role (role),
    INDEX idx_status (status)
);

-- ============================================
-- Donors Table
-- ============================================
CREATE TABLE IF NOT EXISTS donors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    blood_group ENUM('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-') NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    weight DECIMAL(5, 2),
    height DECIMAL(5, 2),
    medical_conditions TEXT,
    allergies TEXT,
    last_donation_date DATE,
    total_donations INT DEFAULT 0,
    total_units_donated DECIMAL(10, 2) DEFAULT 0,
    is_eligible BOOLEAN DEFAULT TRUE,
    qr_code VARCHAR(255),
    wallet_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_blood_group (blood_group),
    INDEX idx_is_eligible (is_eligible),
    INDEX idx_wallet_address (wallet_address)
);

-- ============================================
-- Blood Banks Table
-- ============================================
CREATE TABLE IF NOT EXISTS blood_banks (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    bank_name VARCHAR(150) NOT NULL,
    license_number VARCHAR(100) UNIQUE,
    bank_code VARCHAR(50) UNIQUE NOT NULL,
    license_expiry DATE,
    storage_capacity INT,
    current_storage_usage INT DEFAULT 0,
    contact_person VARCHAR(150),
    contact_phone VARCHAR(20),
    manager_id INT,
    registration_date DATE,
    accreditation_status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    wallet_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES users(id),
    INDEX idx_bank_code (bank_code),
    INDEX idx_accreditation_status (accreditation_status),
    INDEX idx_wallet_address (wallet_address)
);

-- ============================================
-- Hospitals Table
-- ============================================
CREATE TABLE IF NOT EXISTS hospitals (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    hospital_name VARCHAR(150) NOT NULL,
    registration_number VARCHAR(100) UNIQUE,
    hospital_code VARCHAR(50) UNIQUE NOT NULL,
    hospital_type ENUM('Government', 'Private', 'NGO') NOT NULL,
    bed_capacity INT,
    contact_person VARCHAR(150),
    contact_phone VARCHAR(20),
    emergency_contact VARCHAR(20),
    blood_bank_id INT,
    registration_date DATE,
    accreditation_status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    wallet_address VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (blood_bank_id) REFERENCES blood_banks(id),
    INDEX idx_hospital_code (hospital_code),
    INDEX idx_hospital_type (hospital_type),
    INDEX idx_accreditation_status (accreditation_status),
    INDEX idx_wallet_address (wallet_address)
);

-- ============================================
-- Blood Stock Table
-- ============================================
CREATE TABLE IF NOT EXISTS blood_stock (
    id INT PRIMARY KEY AUTO_INCREMENT,
    blood_bank_id INT NOT NULL,
    blood_group ENUM('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-') NOT NULL,
    quantity_units DECIMAL(10, 2) NOT NULL DEFAULT 0,
    minimum_threshold INT DEFAULT 5,
    maximum_capacity INT DEFAULT 50,
    expiry_date DATE,
    storage_location VARCHAR(255),
    temperature_celsius DECIMAL(5, 2),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    blockchain_hash VARCHAR(255),
    FOREIGN KEY (blood_bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE,
    UNIQUE KEY unique_blood_stock (blood_bank_id, blood_group),
    INDEX idx_blood_group (blood_group),
    INDEX idx_quantity_units (quantity_units),
    INDEX idx_expiry_date (expiry_date)
);

-- ============================================
-- Donations Table
-- ============================================
CREATE TABLE IF NOT EXISTS donations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    donation_id VARCHAR(100) UNIQUE NOT NULL,
    donor_id INT NOT NULL,
    blood_bank_id INT NOT NULL,
    blood_group ENUM('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-') NOT NULL,
    quantity_units DECIMAL(10, 2) NOT NULL,
    donation_date DATE NOT NULL,
    donation_time TIME NOT NULL,
    donation_type ENUM('Whole Blood', 'Plasma', 'Platelet', 'Red Blood Cell') DEFAULT 'Whole Blood',
    health_status VARCHAR(255),
    blood_pressure VARCHAR(20),
    hemoglobin_level DECIMAL(5, 2),
    temperature DECIMAL(5, 2),
    donation_status ENUM('completed', 'pending', 'rejected', 'cancelled') DEFAULT 'pending',
    rejection_reason TEXT,
    verified_by INT,
    verified_at TIMESTAMP NULL,
    blockchain_transaction_id VARCHAR(255),
    blockchain_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donor_id) REFERENCES donors(id) ON DELETE CASCADE,
    FOREIGN KEY (blood_bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES users(id),
    UNIQUE KEY unique_donation (donation_id),
    INDEX idx_donor_id (donor_id),
    INDEX idx_blood_bank_id (blood_bank_id),
    INDEX idx_blood_group (blood_group),
    INDEX idx_donation_date (donation_date),
    INDEX idx_donation_status (donation_status),
    INDEX idx_blockchain_hash (blockchain_hash)
);

-- ============================================
-- Blood Requests Table
-- ============================================
CREATE TABLE IF NOT EXISTS blood_requests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    request_id VARCHAR(100) UNIQUE NOT NULL,
    hospital_id INT NOT NULL,
    blood_group ENUM('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-') NOT NULL,
    quantity_units DECIMAL(10, 2) NOT NULL,
    reason TEXT NOT NULL,
    urgency ENUM('routine', 'urgent', 'emergency') DEFAULT 'routine',
    patient_name VARCHAR(150),
    patient_age INT,
    patient_gender ENUM('Male', 'Female', 'Other'),
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    required_date DATE NOT NULL,
    request_status ENUM('pending', 'approved', 'rejected', 'fulfilled', 'cancelled') DEFAULT 'pending',
    approved_by INT,
    approved_at TIMESTAMP NULL,
    fulfilled_by INT,
    fulfilled_at TIMESTAMP NULL,
    blood_bank_id INT,
    notes TEXT,
    blockchain_transaction_id VARCHAR(255),
    blockchain_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id),
    FOREIGN KEY (fulfilled_by) REFERENCES users(id),
    FOREIGN KEY (blood_bank_id) REFERENCES blood_banks(id),
    UNIQUE KEY unique_request (request_id),
    INDEX idx_hospital_id (hospital_id),
    INDEX idx_blood_group (blood_group),
    INDEX idx_urgency (urgency),
    INDEX idx_request_status (request_status),
    INDEX idx_required_date (required_date),
    INDEX idx_blockchain_hash (blockchain_hash)
);

-- ============================================
-- Blood Transfers Table
-- ============================================
CREATE TABLE IF NOT EXISTS blood_transfers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transfer_id VARCHAR(100) UNIQUE NOT NULL,
    donation_id INT NOT NULL,
    from_blood_bank_id INT NOT NULL,
    to_hospital_id INT NOT NULL,
    blood_group ENUM('O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-') NOT NULL,
    quantity_units DECIMAL(10, 2) NOT NULL,
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    transfer_status ENUM('pending', 'in_transit', 'delivered', 'cancelled') DEFAULT 'pending',
    released_by INT,
    released_at TIMESTAMP NULL,
    received_by INT,
    received_at TIMESTAMP NULL,
    shipping_temperature DECIMAL(5, 2),
    delivery_notes TEXT,
    blockchain_transaction_id VARCHAR(255),
    blockchain_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE CASCADE,
    FOREIGN KEY (from_blood_bank_id) REFERENCES blood_banks(id) ON DELETE CASCADE,
    FOREIGN KEY (to_hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    FOREIGN KEY (released_by) REFERENCES users(id),
    FOREIGN KEY (received_by) REFERENCES users(id),
    UNIQUE KEY unique_transfer (transfer_id),
    INDEX idx_blood_group (blood_group),
    INDEX idx_transfer_status (transfer_status),
    INDEX idx_transfer_date (transfer_date),
    INDEX idx_blockchain_hash (blockchain_hash)
);

-- ============================================
-- Blockchain Transactions Table
-- ============================================
CREATE TABLE IF NOT EXISTS blockchain_transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_type ENUM('donation', 'request', 'transfer', 'verification') NOT NULL,
    transaction_reference_id VARCHAR(100),
    transaction_hash VARCHAR(255) UNIQUE NOT NULL,
    wallet_from VARCHAR(255),
    wallet_to VARCHAR(255),
    blockchain_data JSON,
    transaction_status ENUM('pending', 'confirmed', 'failed') DEFAULT 'pending',
    gas_used VARCHAR(50),
    gas_price VARCHAR(50),
    block_number INT,
    confirmation_count INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL,
    INDEX idx_transaction_hash (transaction_hash),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_transaction_status (transaction_status),
    INDEX idx_created_at (created_at),
    INDEX idx_block_number (block_number)
);

-- ============================================
-- Admin Logs Table (Audit Trail)
-- ============================================
CREATE TABLE IF NOT EXISTS admin_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INT,
    old_value JSON,
    new_value JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_action (action),
    INDEX idx_entity_type (entity_type),
    INDEX idx_created_at (created_at)
);

-- ============================================
-- Notifications Table
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'error', 'success', 'emergency') DEFAULT 'info',
    related_entity_type VARCHAR(100),
    related_entity_id INT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read),
    INDEX idx_created_at (created_at)
);

-- ============================================
-- System Settings Table
-- ============================================
CREATE TABLE IF NOT EXISTS system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
    description TEXT,
    updated_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(id),
    INDEX idx_setting_key (setting_key)
);

-- ============================================
-- Create Indexes for Performance
-- ============================================
CREATE INDEX idx_users_role_status ON users(role, status);
CREATE INDEX idx_blood_stock_bloodbank_group ON blood_stock(blood_bank_id, blood_group);
CREATE INDEX idx_donations_bloodbank_date ON donations(blood_bank_id, donation_date);
CREATE INDEX idx_requests_hospital_status ON blood_requests(hospital_id, request_status);
CREATE INDEX idx_transfers_status_date ON blood_transfers(transfer_status, transfer_date);

-- ============================================
-- Insert Initial System Settings
-- ============================================
INSERT INTO system_settings (setting_key, setting_value, setting_type, description) VALUES
('app_name', 'Blockchain Blood Bank Management System', 'string', 'Application Name'),
('app_version', '1.0.0', 'string', 'Application Version'),
('app_description', 'Secure decentralized blood bank management using blockchain technology', 'string', 'Application Description'),
('blockchain_enabled', 'true', 'boolean', 'Enable blockchain integration'),
('email_notifications_enabled', 'true', 'boolean', 'Enable email notifications'),
('sms_notifications_enabled', 'false', 'boolean', 'Enable SMS notifications'),
('min_donation_age', '18', 'integer', 'Minimum age for blood donation'),
('max_donation_age', '65', 'integer', 'Maximum age for blood donation'),
('donation_interval_days', '56', 'integer', 'Days between donations'),
('min_weight_kg', '45', 'integer', 'Minimum weight for donation in kg'),
('blood_expiry_days', '42', 'integer', 'Blood shelf life in days'),
('emergency_blood_alert_threshold', '5', 'integer', 'Alert when blood units below threshold'),
('blockchain_network', 'ganache', 'string', 'Blockchain network (ganache/ropsten/mainnet)'),
('smart_contract_address', '0x0000000000000000000000000000000000000000', 'string', 'Deployed smart contract address');

COMMIT;