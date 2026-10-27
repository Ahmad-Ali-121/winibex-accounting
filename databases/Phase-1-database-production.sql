-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Oct 27, 2026 at 05:13 PM
-- Server version: 11.8.9-MariaDB-log
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `u871859756_winibex_books`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL COMMENT 'Winibex bank, Office cash, Petty cash',
  `type` enum('bank','cash','petty_cash','cheque','pass_through') NOT NULL,
  `coa_id` bigint(20) UNSIGNED NOT NULL COMMENT 'The ledger code whose posted lines make up this balance',
  `owner_user_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Set for pass-through accounts, which are a person own account holding company money in transit',
  `opening_date` date NOT NULL COMMENT 'Earliest date any entry on this account may carry',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `name`, `type`, `coa_id`, `owner_user_id`, `opening_date`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Winibex bank', 'bank', 6, NULL, '2025-03-01', 1, '2026-10-03 06:01:51', '2026-10-03 06:01:51'),
(2, 'Office cash', 'cash', 4, NULL, '2025-03-01', 1, '2026-10-03 06:01:51', '2026-10-03 06:01:51'),
(3, 'Petty cash', 'petty_cash', 5, NULL, '2025-03-01', 1, '2026-10-03 06:01:51', '2026-10-03 06:01:51'),
(4, 'Cheques in hand', 'cheque', 7, NULL, '2025-03-01', 1, '2026-10-03 06:01:51', '2026-10-03 06:01:51'),
(5, 'Platform balances', 'bank', 10, NULL, '2025-03-01', 1, '2026-10-03 06:01:51', '2026-10-03 06:01:51');

-- --------------------------------------------------------

--
-- Table structure for table `attachments`
--

CREATE TABLE `attachments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Null while the upload is not yet attached to an entry',
  `document_type` enum('receipt','bank_advice','bank_statement','tax_certificate','invoice_received','contract','other') NOT NULL,
  `file_path` varchar(255) NOT NULL,
  `mime` varchar(100) NOT NULL,
  `size_bytes` bigint(20) UNSIGNED NOT NULL,
  `sha256` char(64) NOT NULL,
  `uploaded_by` bigint(20) UNSIGNED NOT NULL,
  `retain_until` date NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

--
-- Dumping data for table `attachments`
--

INSERT INTO `attachments` (`id`, `transaction_id`, `document_type`, `file_path`, `mime`, `size_bytes`, `sha256`, `uploaded_by`, `retain_until`, `created_at`) VALUES
(1, 4, 'receipt', 'receipts/2026/10/72f39cd33e8268c3ffb5b6376502255a.jpg', 'image/jpeg', 7968, '88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48', 1, '2036-10-27', '2026-10-27 12:05:10'),
(2, 5, 'receipt', 'receipts/2026/10/decd4f1b04327c491c11c70a2ddaece1.jpg', 'image/jpeg', 7968, '88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48', 1, '2036-10-27', '2026-10-27 13:41:53'),
(3, 8, 'receipt', 'receipts/2026/10/12420ca8857c25a3d165b813f18d848a.jpg', 'image/jpeg', 7968, '88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48', 4, '2036-10-27', '2026-10-27 13:48:15');

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Null for actions by a job rather than a person',
  `table_name` varchar(64) NOT NULL,
  `record_id` bigint(20) UNSIGNED DEFAULT NULL,
  `action` varchar(30) NOT NULL COMMENT 'insert, update, status change, login, and so on',
  `before_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Text on MariaDB. Stringify on write, parse on read' CHECK (json_valid(`before_json`)),
  `after_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`after_json`)),
  `ip` varchar(45) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`id`, `user_id`, `table_name`, `record_id`, `action`, `before_json`, `after_json`, `ip`, `created_at`) VALUES
(1, 1, 'transactions', 1, 'insert', NULL, '{\"status\":\"draft\",\"amount\":56000000,\"description\":\"Opening balances at 30 June 2026 (TEST)\"}', '39.46.176.84', '2026-10-27 03:29:18'),
(2, 1, 'transactions', 1, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-1\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 03:29:18'),
(3, 1, 'transactions', 1, 'status_change', NULL, '{\"openingEntry\":true,\"total\":56000000,\"date\":\"2026-07-01\"}', '39.46.176.84', '2026-10-27 03:29:18'),
(4, 1, 'transactions', 2, 'insert', NULL, '{\"status\":\"draft\",\"amount\":120000,\"description\":\"Printer paper and pens\"}', '39.46.176.84', '2026-10-27 12:03:12'),
(5, 1, 'transactions', 2, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-2\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 12:03:13'),
(6, 1, 'transactions', 3, 'insert', NULL, '{\"status\":\"draft\",\"amount\":15000000,\"description\":\"Website project advance from test client ABC\"}', '39.46.176.84', '2026-10-27 12:04:08'),
(7, 1, 'transactions', 3, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-3\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 12:04:09'),
(8, 1, 'transactions', 4, 'insert', NULL, '{\"status\":\"draft\",\"amount\":560000,\"description\":\"Claude Pro subscription October\"}', '39.46.176.84', '2026-10-27 12:05:09'),
(9, 1, 'attachments', 1, 'insert', NULL, '{\"transactionId\":4,\"documentType\":\"receipt\",\"sizeBytes\":7968,\"sha256\":\"88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48\",\"flagsResolved\":1}', '39.46.176.84', '2026-10-27 12:05:10'),
(10, 1, 'transactions', 4, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-4\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 12:05:11'),
(11, 1, 'transactions', 5, 'insert', NULL, '{\"status\":\"draft\",\"amount\":600000,\"description\":\"Hostinger renewal\"}', '39.46.176.84', '2026-10-27 13:41:11'),
(12, 1, 'transactions', 5, 'update', '{\"amount\":600000,\"description\":\"Hostinger renewal\"}', '{\"amount\":650000,\"description\":\"Hostinger renewal\"}', '39.46.176.84', '2026-10-27 13:41:53'),
(13, 1, 'attachments', 2, 'insert', NULL, '{\"transactionId\":5,\"documentType\":\"receipt\",\"sizeBytes\":7968,\"sha256\":\"88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48\",\"flagsResolved\":1}', '39.46.176.84', '2026-10-27 13:41:53'),
(14, 1, 'transactions', 5, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-5\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 13:41:54'),
(15, 1, 'transactions', 6, 'insert', NULL, '{\"status\":\"draft\",\"amount\":14000000,\"description\":\"Test export client invoice 1001\"}', '39.46.176.84', '2026-10-27 13:45:07'),
(16, 1, 'transactions', 6, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-6\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 13:45:08'),
(17, 4, 'transactions', 7, 'insert', NULL, '{\"status\":\"draft\",\"amount\":220000,\"description\":\"Snacks for team meeting\"}', '39.46.176.84', '2026-10-27 13:47:44'),
(18, 4, 'transactions', 7, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"pending\"}', '39.46.176.84', '2026-10-27 13:47:45'),
(19, 4, 'transactions', 8, 'insert', NULL, '{\"status\":\"draft\",\"amount\":1200000,\"description\":\"Laptop screen repair\"}', '39.46.176.84', '2026-10-27 13:48:15'),
(20, 4, 'attachments', 3, 'insert', NULL, '{\"transactionId\":8,\"documentType\":\"receipt\",\"sizeBytes\":7968,\"sha256\":\"88d8f0173b72c584561e1d98a7efc53e04bad498229d3e7426b0428238531a48\",\"flagsResolved\":1}', '39.46.176.84', '2026-10-27 13:48:15'),
(21, 4, 'transactions', 8, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"pending\"}', '39.46.176.84', '2026-10-27 13:48:16'),
(22, 1, 'transactions', 7, 'status_change', '{\"status\":\"pending\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-7\",\"approvalMethod\":\"owner\",\"possibleSelfApproval\":true}', '39.46.176.84', '2026-10-27 13:49:42'),
(23, 1, 'transactions', 8, 'status_change', '{\"status\":\"pending\"}', '{\"status\":\"rejected\",\"reason\":\"Attach the repair invoice and resubmit\"}', '39.46.176.84', '2026-10-27 13:50:02'),
(24, 1, 'transactions', 9, 'insert', NULL, '{\"status\":\"draft\",\"amount\":6005000,\"description\":\"Cash withdrawal for office\"}', '39.46.176.84', '2026-10-27 17:05:13'),
(25, 1, 'transactions', 9, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-8\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 17:05:13'),
(26, 1, 'transactions', 10, 'insert', NULL, '{\"status\":\"draft\",\"amount\":6000000,\"description\":\"Cash withdrawal for office\"}', '39.46.176.84', '2026-10-27 17:05:13'),
(27, 1, 'transactions', 10, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-9\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 17:05:13'),
(28, 1, 'transactions', 11, 'insert', NULL, '{\"status\":\"draft\",\"amount\":500000,\"description\":\"Petty cash top up\"}', '39.46.176.84', '2026-10-27 17:05:24'),
(29, 1, 'transactions', 11, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-10\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 17:05:24'),
(30, 1, 'transactions', 12, 'insert', NULL, '{\"status\":\"draft\",\"amount\":500000,\"description\":\"Petty cash top up\"}', '39.46.176.84', '2026-10-27 17:05:24'),
(31, 1, 'transactions', 12, 'status_change', '{\"status\":\"draft\"}', '{\"status\":\"posted\",\"journalNumber\":\"JV-11\",\"approvalMethod\":\"auto\",\"possibleSelfApproval\":false}', '39.46.176.84', '2026-10-27 17:05:24'),
(32, 1, 'transactions', 3, 'status_change', '{\"status\":\"posted\"}', '{\"status\":\"reversed\",\"reversedBy\":13,\"reason\":\"Test reversal, wrong client\"}', '39.46.176.84', '2026-10-27 17:05:50'),
(33, 1, 'transactions', 14, 'insert', NULL, '{\"status\":\"draft\",\"amount\":80000,\"description\":\"Idempotency test, should exist once\"}', '39.46.176.84', '2026-10-27 17:06:48'),
(34, 1, 'entry_flags', 1, 'update', '{\"resolved\":false}', '{\"resolved\":true,\"note\":\"Small office supplies, no receipt kept\"}', '39.46.176.84', '2026-10-27 17:09:41');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `main_head` enum('revenue','cgs','admin','selling','financial','taxation','balance_sheet') NOT NULL,
  `direction` enum('in','out') NOT NULL,
  `coa_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Which ledger account this posts to',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `main_head`, `direction`, `coa_id`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Software and app development, export', 'revenue', 'in', 59, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(2, 'Digital marketing, export', 'revenue', 'in', 60, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(3, 'Website development, local', 'revenue', 'in', 61, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(4, 'Social media and ads management', 'revenue', 'in', 62, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(5, 'Design services', 'revenue', 'in', 63, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(6, 'Exchange gain', 'financial', 'in', 64, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(7, 'Bank profit', 'financial', 'in', 65, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(8, 'Investor funds received', 'balance_sheet', 'in', 51, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(9, 'Client advance received', 'balance_sheet', 'in', 44, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(10, 'Rebillable spend recovered', 'balance_sheet', 'in', 15, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(11, 'Transfer in', 'balance_sheet', 'in', 11, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(12, 'Transfer out', 'balance_sheet', 'out', 11, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(13, 'Opening balance', 'balance_sheet', 'in', 57, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(14, 'Outsourcing and subcontractors', 'cgs', 'out', 67, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(15, 'Client advertising spend, absorbed', 'cgs', 'out', 68, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(16, 'Project software and tools', 'cgs', 'out', 69, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(17, 'Platform fees', 'cgs', 'out', 70, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(18, 'Partner profit share', 'cgs', 'out', 71, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(19, 'Project travel', 'cgs', 'out', 72, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(20, 'Salaries and wages', 'admin', 'out', 74, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(21, 'Staff welfare', 'admin', 'out', 75, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(22, 'Rent and utilities', 'admin', 'out', 76, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(23, 'Telecommunication and internet', 'admin', 'out', 77, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(24, 'Software subscriptions', 'admin', 'out', 78, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(25, 'Hosting and domains', 'admin', 'out', 79, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(26, 'Travelling and conveyance', 'admin', 'out', 80, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(27, 'Office supplies, printing and stationery', 'admin', 'out', 81, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(28, 'Repairs and maintenance', 'admin', 'out', 82, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(29, 'Legal, registration and professional fees', 'admin', 'out', 83, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(30, 'Entertainment', 'admin', 'out', 84, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(31, 'Own advertising', 'selling', 'out', 87, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(32, 'Business development', 'selling', 'out', 88, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(33, 'Bank charges and FED', 'financial', 'out', 90, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(34, 'Forex and card fees', 'financial', 'out', 91, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(35, 'Exchange loss', 'financial', 'out', 92, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(36, 'Final tax, Section 154A', 'taxation', 'out', 94, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(37, 'Income tax paid', 'taxation', 'out', 95, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(38, 'Rebillable client spend', 'balance_sheet', 'out', 15, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(39, 'Equipment purchase', 'balance_sheet', 'out', 27, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(40, 'Advance to employee', 'balance_sheet', 'out', 17, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(41, 'Prepaid expense', 'balance_sheet', 'out', 19, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(42, 'Loan repayment to director', 'balance_sheet', 'out', 51, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(43, 'Reimbursement to a person', 'balance_sheet', 'out', 41, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49');

-- --------------------------------------------------------

--
-- Table structure for table `chart_of_accounts`
--

CREATE TABLE `chart_of_accounts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(10) NOT NULL COMMENT 'Four digits. First digit is the class',
  `name` varchar(100) NOT NULL,
  `type` enum('asset','liability','equity','income','expense') NOT NULL,
  `parent_id` bigint(20) UNSIGNED DEFAULT NULL,
  `fbr_return_head_code` varchar(20) DEFAULT NULL COMMENT 'Null until the accountant supplies the mapping',
  `normal_balance` enum('debit','credit') NOT NULL COMMENT 'Contra accounts such as 1219 are credit despite being assets',
  `is_header` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Grouping only, never posted to by any path',
  `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Cannot be renamed or deactivated',
  `allow_manual_posting` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'False for control accounts, written only by their own module',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `chart_of_accounts`
--

INSERT INTO `chart_of_accounts` (`id`, `code`, `name`, `type`, `parent_id`, `fbr_return_head_code`, `normal_balance`, `is_header`, `is_system`, `allow_manual_posting`, `is_active`, `created_at`, `updated_at`) VALUES
(1, '1000', 'Assets', 'asset', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(2, '1100', 'Current assets', 'asset', 1, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(3, '1110', 'Cash and cash equivalents', 'asset', 2, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(4, '1111', 'Cash in hand, office', 'asset', 3, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(5, '1112', 'Petty cash', 'asset', 3, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(6, '1113', 'Bank, Winibex current account', 'asset', 3, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(7, '1114', 'Cheques in hand, uncleared', 'asset', 3, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(8, '1115', 'Funds in transit, Fazal', 'asset', 3, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(9, '1116', 'Funds in transit, Ahmad', 'asset', 3, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(10, '1117', 'Funds held on platforms', 'asset', 3, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(11, '1118', 'Funds in transit, internal', 'asset', 3, NULL, 'debit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(12, '1120', 'Trade receivables', 'asset', 2, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(13, '1121', 'Trade receivables, local', 'asset', 12, NULL, 'debit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(14, '1122', 'Trade receivables, foreign', 'asset', 12, NULL, 'debit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(15, '1123', 'Rebillable expenses recoverable', 'asset', 12, NULL, 'debit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(16, '1130', 'Advances, deposits and prepayments', 'asset', 2, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(17, '1131', 'Advances to employees', 'asset', 16, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(18, '1132', 'Advances to suppliers', 'asset', 16, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(19, '1133', 'Prepaid expenses', 'asset', 16, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(20, '1134', 'Security deposits', 'asset', 16, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(21, '1140', 'Tax assets', 'asset', 2, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(22, '1141', 'Advance income tax, adjustable', 'asset', 21, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(23, '1142', 'Income tax withheld by customers', 'asset', 21, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(24, '1143', 'Sales tax input, PRA', 'asset', 21, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(25, '1200', 'Non-current assets', 'asset', 1, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(26, '1210', 'Property and equipment', 'asset', 25, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(27, '1211', 'Computers and IT equipment', 'asset', 26, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(28, '1212', 'Furniture and fixtures', 'asset', 26, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(29, '1213', 'Office equipment', 'asset', 26, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(30, '1219', 'Accumulated depreciation', 'asset', 26, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(31, '1220', 'Intangible assets', 'asset', 25, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(32, '1221', 'Software and licences', 'asset', 31, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(33, '1222', 'Website and domain', 'asset', 31, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(34, '1229', 'Accumulated amortisation', 'asset', 31, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(35, '2000', 'Liabilities', 'liability', NULL, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(36, '2100', 'Current liabilities', 'liability', 35, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(37, '2110', 'Trade and other payables', 'liability', 36, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(38, '2111', 'Payable to suppliers', 'liability', 37, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(39, '2112', 'Payable to contractors', 'liability', 37, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(40, '2113', 'Accrued expenses', 'liability', 37, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(41, '2114', 'Payable to employees, reimbursements', 'liability', 37, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(42, '2115', 'Partner share payable', 'liability', 37, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(43, '2120', 'Salaries payable', 'liability', 36, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(44, '2140', 'Advances from customers', 'liability', 36, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(45, '2130', 'Tax liabilities', 'liability', 36, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(46, '2131', 'Withholding payable, salaries (s.149)', 'liability', 45, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(47, '2132', 'Withholding payable, services and suppliers (s.153)', 'liability', 45, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(48, '2133', 'Sales tax payable, PRA', 'liability', 45, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(49, '2134', 'Income tax payable', 'liability', 45, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(50, '2200', 'Non-current liabilities', 'liability', 35, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(51, '2210', 'Loan from director, Hammad Malik', 'liability', 50, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(52, '2220', 'Loans from other investors', 'liability', 50, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(53, '3000', 'Equity', 'equity', NULL, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(54, '3100', 'Share capital', 'equity', 53, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(55, '3200', 'Retained earnings or accumulated loss', 'equity', 53, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(56, '3300', 'Current year profit or loss', 'equity', 53, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(57, '3400', 'Opening balance equity', 'equity', 53, NULL, 'credit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(58, '4000', 'Income', 'income', NULL, NULL, 'credit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(59, '4110', 'Software and app development, export', 'income', 58, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(60, '4120', 'Digital marketing services, export', 'income', 58, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(61, '4210', 'Website development, local', 'income', 58, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(62, '4220', 'Social media and ads management, local', 'income', 58, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(63, '4230', 'Design services', 'income', 58, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(64, '4310', 'Exchange gain', 'income', 58, NULL, 'credit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(65, '4320', 'Bank profit', 'income', 58, NULL, 'credit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(66, '5000', 'Cost of services', 'expense', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(67, '5100', 'Outsourcing and subcontractors', 'expense', 66, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(68, '5200', 'Client advertising spend, absorbed', 'expense', 66, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(69, '5300', 'Project software and tools', 'expense', 66, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(70, '5400', 'Platform fees', 'expense', 66, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(71, '5500', 'Partner profit share', 'expense', 66, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(72, '5600', 'Project travel', 'expense', 66, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(73, '6000', 'Administrative expenses', 'expense', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(74, '6100', 'Salaries and wages', 'expense', 73, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(75, '6110', 'Staff welfare', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(76, '6200', 'Rent and utilities', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(77, '6300', 'Telecommunication and internet', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(78, '6400', 'Software subscriptions', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(79, '6410', 'Hosting and domains', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(80, '6500', 'Travelling and conveyance', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(81, '6600', 'Office supplies, printing and stationery', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(82, '6700', 'Repairs and maintenance', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(83, '6800', 'Legal, registration and professional fees', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(84, '6900', 'Entertainment', 'expense', 73, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(85, '6950', 'Depreciation and amortisation', 'expense', 73, NULL, 'debit', 0, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(86, '7000', 'Selling and marketing', 'expense', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(87, '7100', 'Own advertising', 'expense', 86, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(88, '7200', 'Business development', 'expense', 86, NULL, 'debit', 0, 0, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(89, '8000', 'Finance costs and other', 'expense', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(90, '8100', 'Bank charges and FED', 'expense', 89, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(91, '8200', 'Forex and card fees', 'expense', 89, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(92, '8300', 'Exchange loss', 'expense', 89, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(93, '9000', 'Taxation', 'expense', NULL, NULL, 'debit', 1, 1, 0, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(94, '9100', 'Final tax, Section 154A', 'expense', 93, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(95, '9200', 'Current income tax, normal regime', 'expense', 93, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49'),
(96, '9300', 'Minimum tax', 'expense', 93, NULL, 'debit', 0, 1, 1, 1, '2026-10-03 06:00:49', '2026-10-03 06:00:49');

-- --------------------------------------------------------

--
-- Table structure for table `cheques`
--

CREATE TABLE `cheques` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `account_id` bigint(20) UNSIGNED NOT NULL,
  `cheque_number` varchar(30) NOT NULL,
  `payee` varchar(150) NOT NULL,
  `amount` bigint(20) NOT NULL COMMENT 'PKR paisa',
  `issue_date` date NOT NULL,
  `status` enum('issued','presented','cleared','bounced','cancelled') NOT NULL DEFAULT 'issued',
  `cleared_on` date DEFAULT NULL,
  `transaction_id` bigint(20) UNSIGNED DEFAULT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `company_profile`
--

CREATE TABLE `company_profile` (
  `id` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `legal_name` varchar(150) NOT NULL,
  `trade_name` varchar(150) NOT NULL DEFAULT '',
  `ntn` varchar(20) NOT NULL DEFAULT '',
  `strn_pra` varchar(20) NOT NULL DEFAULT '' COMMENT 'Blank until PRA registration, if it ever happens',
  `pseb_reg_no` varchar(40) NOT NULL DEFAULT '',
  `pseb_valid_until` date DEFAULT NULL COMMENT 'Drives the certificate expiry warning',
  `secp_reg_no` varchar(40) NOT NULL DEFAULT '',
  `paid_up_capital` bigint(20) NOT NULL DEFAULT 0 COMMENT 'Paisa. Drives the audit exemption note on the statements',
  `address` varchar(255) NOT NULL DEFAULT '',
  `phone` varchar(40) NOT NULL DEFAULT '',
  `email` varchar(190) NOT NULL DEFAULT '',
  `website` varchar(190) NOT NULL DEFAULT '',
  `logo_path` varchar(255) DEFAULT NULL,
  `bank_details_text` text DEFAULT NULL,
  `default_terms_text` text DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `company_profile`
--

INSERT INTO `company_profile` (`id`, `legal_name`, `trade_name`, `ntn`, `strn_pra`, `pseb_reg_no`, `pseb_valid_until`, `secp_reg_no`, `paid_up_capital`, `address`, `phone`, `email`, `website`, `logo_path`, `bank_details_text`, `default_terms_text`, `updated_at`) VALUES
(1, 'Winibex (Private) Limited', 'Winibex', '', '', '', NULL, '', 0, '', '', '', '', NULL, NULL, NULL, '2026-10-03 06:01:51');

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

CREATE TABLE `currencies` (
  `code` char(3) NOT NULL,
  `name` varchar(50) NOT NULL,
  `symbol` varchar(8) NOT NULL,
  `minor_units` tinyint(3) UNSIGNED NOT NULL DEFAULT 2 COMMENT 'Decimal places. 2 for every currency used today',
  `is_active` tinyint(1) NOT NULL DEFAULT 1
) ;

--
-- Dumping data for table `currencies`
--

INSERT INTO `currencies` (`code`, `name`, `symbol`, `minor_units`, `is_active`) VALUES
('AED', 'UAE Dirham', 'AED', 2, 1),
('EUR', 'Euro', '€', 2, 1),
('GBP', 'Pound Sterling', '£', 2, 1),
('PKR', 'Pakistani Rupee', 'Rs', 2, 1),
('QAR', 'Qatari Riyal', 'QAR', 2, 1),
('USD', 'US Dollar', '$', 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `entry_flags`
--

CREATE TABLE `entry_flags` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `severity` enum('warning','flag') NOT NULL,
  `code` varchar(50) NOT NULL COMMENT 'possible_duplicate, no_receipt, unusual_amount, closed_client, backdated, thin_description',
  `detail` varchar(255) NOT NULL COMMENT 'Names the record it matched against. A warning the user cannot investigate is one they dismiss by reflex',
  `acknowledged_by` bigint(20) UNSIGNED DEFAULT NULL,
  `acknowledged_at` datetime DEFAULT NULL,
  `resolved` tinyint(1) NOT NULL DEFAULT 0,
  `resolved_by` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Who marked it reviewed. NULL when it resolved itself',
  `resolved_at` datetime DEFAULT NULL COMMENT 'UTC',
  `resolution_note` varchar(255) DEFAULT NULL COMMENT 'Why it needs nothing more, or what resolved it',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

--
-- Dumping data for table `entry_flags`
--

INSERT INTO `entry_flags` (`id`, `transaction_id`, `severity`, `code`, `detail`, `acknowledged_by`, `acknowledged_at`, `resolved`, `resolved_by`, `resolved_at`, `resolution_note`, `created_at`) VALUES
(1, 2, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 1, 1, '2026-10-27 17:09:41', 'Small office supplies, no receipt kept', '2026-10-27 12:03:12'),
(2, 4, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 1, NULL, '2026-10-27 12:05:10', 'Receipt attached', '2026-10-27 12:05:09'),
(4, 5, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 1, NULL, '2026-10-27 13:41:53', 'Receipt attached', '2026-10-27 13:41:53'),
(5, 7, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 0, NULL, NULL, NULL, '2026-10-27 13:47:44'),
(6, 8, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 1, NULL, '2026-10-27 13:48:15', 'Receipt attached', '2026-10-27 13:48:15'),
(7, 14, 'flag', 'NO_RECEIPT', 'No receipt attached.', NULL, NULL, 0, NULL, NULL, NULL, '2026-10-27 17:06:48');

-- --------------------------------------------------------

--
-- Table structure for table `fbr_return_heads`
--

CREATE TABLE `fbr_return_heads` (
  `code` varchar(20) NOT NULL COMMENT 'Return line code',
  `name` varchar(200) NOT NULL,
  `schedule` varchar(100) NOT NULL DEFAULT '',
  `tax_year_from` smallint(5) UNSIGNED DEFAULT NULL COMMENT 'Return formats change between years',
  `tax_year_to` smallint(5) UNSIGNED DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `idempotency_keys`
--

CREATE TABLE `idempotency_keys` (
  `idempotency_key` char(36) NOT NULL COMMENT 'Not named key, which is a reserved word',
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `endpoint` varchar(120) NOT NULL,
  `request_hash` char(64) DEFAULT NULL COMMENT 'SHA-256 of the request body the key was first used with',
  `response_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Returned as-is on a repeat request' CHECK (json_valid(`response_json`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `idempotency_keys`
--

INSERT INTO `idempotency_keys` (`idempotency_key`, `user_id`, `endpoint`, `request_hash`, `response_json`, `created_at`) VALUES
('02eaf5e4-98b3-4bfd-9924-a7fcbc07297d', 1, 'POST /api/v1/transactions', '40809ed51b6d708f9324018a00aebe1fa37e83cfc9439e1f8ee945e2bcd2fdc9', '{\"status\":201,\"body\":{\"transaction\":{\"id\":4,\"gross\":560000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":560000}}}', '2026-10-27 12:05:09'),
('039947a4-eec0-4e04-a0d7-aa4dcd51044f', 1, 'POST /api/v1/transactions', 'cace7778f2cd6168628829bd1b7c905507a210fea22c1335614b3bf7303a0579', '{\"status\":201,\"body\":{\"transaction\":{\"id\":2,\"gross\":120000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":120000}}}', '2026-10-27 12:03:12'),
('0dda99c7-38c0-426f-acd8-a4037987e8e2', 1, 'POST /api/v1/transactions/6/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":6,\"status\":\"posted\",\"journalNumber\":\"JV-6\",\"lines\":[{\"coaId\":6,\"debit\":14000000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":59,\"debit\":0,\"credit\":14000000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 13:45:08'),
('0ff42f74-f908-4df7-9a74-3cd55fdce758', 1, 'POST /api/v1/opening-entry', 'c707fd2aa8074e63e88e949e8e4a181c1c4946f6f45b7d2717b70e0a4885a670', '{\"status\":201,\"body\":{\"openingEntry\":{\"transactionId\":1,\"journalNumber\":\"JV-1\",\"date\":\"2026-07-01\",\"total\":{\"minor\":56000000,\"currency\":\"PKR\"},\"lines\":5}}}', '2026-10-27 03:29:18'),
('5d916c1a-9796-441c-8490-7853832d6209', 1, 'POST /api/v1/transactions/7/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":7,\"status\":\"posted\",\"journalNumber\":\"JV-7\",\"lines\":[{\"coaId\":75,\"debit\":220000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":5,\"debit\":0,\"credit\":220000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 13:49:42'),
('7a2e3d4c-5b6f-4a71-9b8c-0d1e2f3a4b5c', 1, 'POST /api/v1/transactions', '5799a1704debc2be6e39f42395f953d93fa0a4c99aefcd696a6b2252f4a4a9f5', '{\"status\":201,\"body\":{\"transaction\":{\"id\":14,\"gross\":80000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":80000}}}', '2026-10-27 17:06:48'),
('8488f4eb-7a91-44ad-b20c-ad24cc41d24d', 1, 'POST /api/v1/transactions/3/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":3,\"status\":\"posted\",\"journalNumber\":\"JV-3\",\"lines\":[{\"coaId\":6,\"debit\":15000000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":61,\"debit\":0,\"credit\":15000000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 12:04:09'),
('8a0bb835-dcbd-474c-bda5-949c6b6180fb', 1, 'POST /api/v1/transactions', '40f799bb39fa0ff6512d18f943eb62d312b03d2a3dea6c87d7924dc726f2e1f6', '{\"status\":201,\"body\":{\"transaction\":{\"id\":5,\"gross\":600000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":600000}}}', '2026-10-27 13:41:11'),
('91e376c1-3f65-418a-bcc7-327ebba73307', 1, 'POST /api/v1/transactions/3/reverse', '1b0add0477fc3a51a488cae7a93d556f9462cede0081731a04f59e21c4e0cd2b', '{\"status\":200,\"body\":{\"id\":3,\"reversalId\":13,\"journalNumber\":\"JV-12\",\"lines\":[{\"coaId\":6,\"debit\":0,\"credit\":15000000,\"memo\":null,\"lineNo\":1},{\"coaId\":61,\"debit\":15000000,\"credit\":0,\"memo\":null,\"lineNo\":2}]}}', '2026-10-27 17:05:50'),
('9504bd08-47d5-4dcb-99c6-642775784ecb', 1, 'POST /api/v1/transfers', '45a49b90c03f7d307111500e79b3798955ee85abf52a08442f13203c331a5069', '{\"status\":201,\"body\":{\"transfer\":{\"transferGroupId\":\"ff04fb5a-fb7e-4b5f-afcf-95c27a12d96b\",\"amount\":6000000,\"fee\":5000,\"from\":{\"accountId\":1,\"name\":\"Winibex bank\",\"transactionId\":9,\"journalNumber\":\"JV-8\"},\"to\":{\"accountId\":2,\"name\":\"Office cash\",\"transactionId\":10,\"journalNumber\":\"JV-9\"}}}}', '2026-10-27 17:05:13'),
('964b57c1-4367-485e-95ec-8f8d60e8d976', 1, 'POST /api/v1/transfers', '8cbd6f8a2ad4306d9485f918fa647cff21c60afd6e06e5e977edd91eea661c78', '{\"status\":201,\"body\":{\"transfer\":{\"transferGroupId\":\"5a70591c-a151-4af1-b1aa-1f8c4df5c7ee\",\"amount\":500000,\"fee\":0,\"from\":{\"accountId\":2,\"name\":\"Office cash\",\"transactionId\":11,\"journalNumber\":\"JV-10\"},\"to\":{\"accountId\":3,\"name\":\"Petty cash\",\"transactionId\":12,\"journalNumber\":\"JV-11\"}}}}', '2026-10-27 17:05:24'),
('b65c6079-d057-4a03-b0ba-cd436602dd06', 4, 'POST /api/v1/transactions', 'b96702c61311f1c0ef00f249b570ff7742e4c995365828cb8ce0ac479b685962', '{\"status\":201,\"body\":{\"transaction\":{\"id\":8,\"gross\":1200000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":1200000}}}', '2026-10-27 13:48:15'),
('cfaa0fd6-20f0-426d-9af5-532f6efe17f9', 1, 'POST /api/v1/transactions', '02ae7f135c8270cbaa6d6a9c01910feecd3bc6cd37af19f1ace03d2d168e760d', '{\"status\":201,\"body\":{\"transaction\":{\"id\":6,\"gross\":14000000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":14000000}}}', '2026-10-27 13:45:07'),
('d6391637-66fa-45cc-8f8a-c03ef21d8e26', 1, 'POST /api/v1/transactions/2/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":2,\"status\":\"posted\",\"journalNumber\":\"JV-2\",\"lines\":[{\"coaId\":81,\"debit\":120000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":4,\"debit\":0,\"credit\":120000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 12:03:13'),
('d98af607-bcd4-475e-8dc9-734634757880', 4, 'POST /api/v1/transactions', '16ebfb258142c8e8484421a04983c3d9508e46db01d21ec98203bd13a1e93f7d', '{\"status\":201,\"body\":{\"transaction\":{\"id\":7,\"gross\":220000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":220000}}}', '2026-10-27 13:47:44'),
('e16d10c5-4264-4b38-b987-b1f84a2e0e0f', 1, 'POST /api/v1/transactions/5/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":5,\"status\":\"posted\",\"journalNumber\":\"JV-5\",\"lines\":[{\"coaId\":79,\"debit\":650000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":6,\"debit\":0,\"credit\":650000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 13:41:54'),
('e7930335-3415-4b21-820c-e884abcf62aa', 1, 'POST /api/v1/transactions/4/approve', '44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a', '{\"status\":200,\"body\":{\"id\":4,\"status\":\"posted\",\"journalNumber\":\"JV-4\",\"lines\":[{\"coaId\":78,\"debit\":560000,\"credit\":0,\"memo\":null,\"lineNo\":1},{\"coaId\":6,\"debit\":0,\"credit\":560000,\"memo\":null,\"lineNo\":2}],\"alreadyWritten\":false}}', '2026-10-27 12:05:11'),
('f17c9320-67df-4866-bdfc-867667a0e8b7', 1, 'POST /api/v1/transactions', 'd37a30b2c022356fd1f2c0297b1a54f93d61095aab6de2ac40c7b3aceb87dcac', '{\"status\":201,\"body\":{\"transaction\":{\"id\":3,\"gross\":15000000,\"taxTotal\":0,\"chargesTotal\":0,\"withheldTotal\":0,\"amount\":15000000}}}', '2026-10-27 12:04:08');

-- --------------------------------------------------------

--
-- Table structure for table `journal_lines`
--

CREATE TABLE `journal_lines` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `coa_id` bigint(20) UNSIGNED NOT NULL,
  `debit` bigint(20) NOT NULL DEFAULT 0 COMMENT 'PKR paisa',
  `credit` bigint(20) NOT NULL DEFAULT 0 COMMENT 'PKR paisa',
  `line_no` int(11) NOT NULL COMMENT 'Display order within the entry',
  `memo` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

--
-- Dumping data for table `journal_lines`
--

INSERT INTO `journal_lines` (`id`, `transaction_id`, `coa_id`, `debit`, `credit`, `line_no`, `memo`, `created_at`) VALUES
(1, 1, 6, 50000000, 0, 1, 'Balance at 2026-06-30', '2026-10-27 03:29:18'),
(2, 1, 4, 5000000, 0, 2, 'Balance at 2026-06-30', '2026-10-27 03:29:18'),
(3, 1, 5, 1000000, 0, 3, 'Balance at 2026-06-30', '2026-10-27 03:29:18'),
(4, 1, 51, 0, 20000000, 4, 'Balance at 2026-06-30', '2026-10-27 03:29:18'),
(5, 1, 57, 0, 36000000, 5, 'Opening balance equity, the balancing figure', '2026-10-27 03:29:18'),
(6, 2, 81, 120000, 0, 1, NULL, '2026-10-27 12:03:13'),
(7, 2, 4, 0, 120000, 2, NULL, '2026-10-27 12:03:13'),
(8, 3, 6, 15000000, 0, 1, NULL, '2026-10-27 12:04:09'),
(9, 3, 61, 0, 15000000, 2, NULL, '2026-10-27 12:04:09'),
(10, 4, 78, 560000, 0, 1, NULL, '2026-10-27 12:05:11'),
(11, 4, 6, 0, 560000, 2, NULL, '2026-10-27 12:05:11'),
(12, 5, 79, 650000, 0, 1, NULL, '2026-10-27 13:41:54'),
(13, 5, 6, 0, 650000, 2, NULL, '2026-10-27 13:41:54'),
(14, 6, 6, 14000000, 0, 1, NULL, '2026-10-27 13:45:08'),
(15, 6, 59, 0, 14000000, 2, NULL, '2026-10-27 13:45:08'),
(16, 7, 75, 220000, 0, 1, NULL, '2026-10-27 13:49:42'),
(17, 7, 5, 0, 220000, 2, NULL, '2026-10-27 13:49:42'),
(18, 9, 11, 6000000, 0, 1, NULL, '2026-10-27 17:05:13'),
(19, 9, 90, 5000, 0, 2, 'Transfer fee', '2026-10-27 17:05:13'),
(20, 9, 6, 0, 6005000, 3, NULL, '2026-10-27 17:05:13'),
(21, 10, 4, 6000000, 0, 1, NULL, '2026-10-27 17:05:13'),
(22, 10, 11, 0, 6000000, 2, NULL, '2026-10-27 17:05:13'),
(23, 11, 11, 500000, 0, 1, NULL, '2026-10-27 17:05:24'),
(24, 11, 4, 0, 500000, 2, NULL, '2026-10-27 17:05:24'),
(25, 12, 5, 500000, 0, 1, NULL, '2026-10-27 17:05:24'),
(26, 12, 11, 0, 500000, 2, NULL, '2026-10-27 17:05:24'),
(27, 13, 6, 0, 15000000, 1, NULL, '2026-10-27 17:05:50'),
(28, 13, 61, 15000000, 0, 2, NULL, '2026-10-27 17:05:50');

--
-- Triggers `journal_lines`
--
DELIMITER $$
CREATE TRIGGER `trg_journal_lines_no_delete` BEFORE DELETE ON `journal_lines` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Journal lines are never deleted. Post a reversing entry.';
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_journal_lines_no_update` BEFORE UPDATE ON `journal_lines` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Journal lines cannot be changed. Post a reversing entry.';
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `period_locks`
--

CREATE TABLE `period_locks` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `period_month` tinyint(3) UNSIGNED NOT NULL,
  `period_year` smallint(5) UNSIGNED NOT NULL,
  `locked_by` bigint(20) UNSIGNED NOT NULL,
  `locked_at` datetime NOT NULL DEFAULT current_timestamp(),
  `note` varchar(255) DEFAULT NULL
) ;

-- --------------------------------------------------------

--
-- Table structure for table `refresh_tokens`
--

CREATE TABLE `refresh_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token_hash` char(64) NOT NULL COMMENT 'SHA-256 of the token. The token itself is never stored',
  `family_id` char(36) NOT NULL COMMENT 'One login session. Reuse of a rotated token revokes the whole family',
  `expires_at` datetime NOT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `replaced_by_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Set on rotation',
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `refresh_tokens`
--

INSERT INTO `refresh_tokens` (`id`, `user_id`, `token_hash`, `family_id`, `expires_at`, `revoked_at`, `replaced_by_id`, `ip`, `user_agent`, `created_at`) VALUES
(1, 1, '8aba0842e66fdc1260969471b3a114d0f649acbf42d3a11e957f762a37d3f51c', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 09:33:36', '2026-10-03 10:05:18', 2, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 09:33:36'),
(2, 1, 'bffd98c365a272120cfd7541a611b6856b10334432cb5848370e95923d23999b', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 10:05:18', '2026-10-03 11:27:47', 3, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 10:05:18'),
(3, 1, '5a203c5e4653ef45526312429d2c54097c9f15eb701b86221ecd7f222e3d6b2c', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 11:27:47', '2026-10-03 11:30:09', 6, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:27:47'),
(4, 1, '2119c4a701dbcfcd1fa75c71a678f4f47664bfebbe2f1a770f651cbc140e0027', 'c30252d5-a4d8-4910-ad49-aaa26a058818', '2026-11-02 11:28:41', '2026-10-03 11:28:51', 5, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:28:41'),
(5, 1, '535c29ae391fe30c62b1302626dcf8ed14c76c49cef4af8295f8457083c96402', 'c30252d5-a4d8-4910-ad49-aaa26a058818', '2026-11-02 11:28:51', '2026-10-04 05:04:30', NULL, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:28:51'),
(6, 1, '0c42922ecf16ddd6f65e8e73a93410472756cc6dcb6e94808c423be1bcf8b881', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 11:30:09', '2026-10-03 11:31:42', 7, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:30:09'),
(7, 1, 'cfcdf81ea02ce412e10408d71da8d6a0142be53ad5e221f493f67c4606abc87a', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 11:31:42', '2026-10-03 11:44:55', 8, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:31:42'),
(8, 1, 'a90be66ebaaa9a804d7d96ecd2e61d007fa8c21514cd0d4f47204a5188df45cd', '490eb36e-a67b-4d8d-a717-795a43921bf3', '2026-11-02 11:44:55', '2026-10-03 11:45:50', NULL, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:44:55'),
(9, 1, 'cb50a1fe36b8752ba30d594080bb4d83f0de76ab1a0017a9e4d7dd64ebfa1250', '13629652-505d-4bd7-becf-cfe55da4346c', '2026-11-02 11:46:00', '2026-10-04 04:46:13', 10, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-03 11:46:00'),
(10, 1, '603967e7c288d32be852bd4870d94b09c670175cf6ad9105ea28a3e536f0b5ea', '13629652-505d-4bd7-becf-cfe55da4346c', '2026-11-03 04:46:13', '2026-10-04 05:00:36', 11, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-04 04:46:13'),
(11, 1, '87554fb5be7d7e8043f4a44408210a626a59702b463fa903313f7295a61fe853', '13629652-505d-4bd7-becf-cfe55da4346c', '2026-11-03 05:00:36', '2026-10-04 05:03:51', 12, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-04 05:00:36'),
(12, 1, 'e2b1724025da1a7e002f85cf80d0d281695daacaa80dbde142ee98af565ed6a7', '13629652-505d-4bd7-becf-cfe55da4346c', '2026-11-03 05:03:51', '2026-10-04 05:03:55', 13, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-04 05:03:51'),
(13, 1, '6ebd40397a60e46569d272fa57765718955b35e5891a50628b345751cadcb6e7', '13629652-505d-4bd7-becf-cfe55da4346c', '2026-11-03 05:03:55', '2026-10-04 05:04:30', NULL, '39.46.180.202', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/154.0.0.0 Safari/537.36', '2026-10-04 05:03:55'),
(14, 1, '23055811dd6a814518f56b2c61c4c1f578e722f8350c524d4e7ba9eabc5d6f6c', '927f15b4-a4d0-4983-9ff7-c495730a35c1', '2026-11-26 01:33:45', '2026-10-27 03:25:32', 15, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 01:33:45'),
(15, 1, '3e7febfaefb2ab5e89881d19d2a6c286ef2f66e9b2d98a7f36afc9b73a1f271d', '927f15b4-a4d0-4983-9ff7-c495730a35c1', '2026-11-26 03:25:32', '2026-10-27 03:25:33', NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 03:25:32'),
(16, 1, 'bf56fda7eaa1b5389cfc909f0fddcaae6eb31229ad009bbdecc4f4203fbe5491', 'b66397b9-ce8c-4cb8-a0bb-3a495d6a3521', '2026-11-26 03:25:58', '2026-10-27 03:28:05', 21, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 03:25:58'),
(17, 1, '74ca9217efe165039eeb80ce40ab6e96d7ac9244c4728ee847d0bf86a2e80ff0', '5f8ca220-4429-4507-8988-dfafceb7d3a7', '2026-11-26 03:26:56', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:26:56'),
(18, 4, 'bc816d85eace713f3440ae404df7c797e35c29cb516f80794539c3fc4fc70f1f', '776a85ae-6529-44ab-a56a-2d4ab6a0b320', '2026-11-26 03:27:03', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:27:03'),
(19, 2, '8754c6a3c4c4f64989a5cc9ac71fccfa03cd88fa11bf351e3835bd3e621dce60', '56005740-42a0-479d-b1c0-dfe026ea3358', '2026-11-26 03:27:07', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:27:07'),
(20, 3, '8a62fb1e233ef7f170757fb0c36eab71b1235f6ff8bcf95d2d822735fa2ef271', 'a9605e1b-db5d-4574-9673-a0e0fa324a38', '2026-11-26 03:27:11', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:27:11'),
(21, 1, '73794d62a4ff2843ea022993a6d2deb1d0654447f9b1a6a78033cd60021044ff', 'b66397b9-ce8c-4cb8-a0bb-3a495d6a3521', '2026-11-26 03:28:05', '2026-10-27 03:28:07', 22, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 03:28:05'),
(22, 1, '5ef918071f24f20405e104308af0b2537f6cde705690b7406f2b9695aeeeb3dd', 'b66397b9-ce8c-4cb8-a0bb-3a495d6a3521', '2026-11-26 03:28:07', '2026-10-27 03:28:14', NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 03:28:07'),
(23, 1, '455bbbc450e1384be299077cc105085388b191eda429067b5fd06b7574172d60', 'be1c1cf7-a563-4f31-80fa-713a4045c1e0', '2026-11-26 03:28:44', '2026-10-27 12:02:19', 26, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 03:28:44'),
(24, 4, '491f4b4697d41de2f19156ff5200e02c033faad4c87e7a711e0ecad5fb9e2fe2', 'b3ed5497-6e94-43a3-9a1e-7f5566c0cdf6', '2026-11-26 03:29:01', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:29:01'),
(25, 1, '4d6b00cf829a0f13bbde90b12ec0b19e3d77da2b07e04d276861413f7cd72aea', '50a6183e-fa0b-4db4-bda1-cb5edb360107', '2026-11-26 03:29:15', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 03:29:15'),
(26, 1, 'd241be0308a85184baae30f33b73404df6c4955e79f2b379cd40c5e599540d04', 'be1c1cf7-a563-4f31-80fa-713a4045c1e0', '2026-11-26 12:02:19', '2026-10-27 13:40:56', 27, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 12:02:19'),
(27, 1, '56e4a941e9273cdbd117a686b93d9b67b05e9190b8f97bf7d487ee860d9dbc29', 'be1c1cf7-a563-4f31-80fa-713a4045c1e0', '2026-11-26 13:40:56', '2026-10-27 13:46:39', NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 13:40:56'),
(28, 4, 'd82bd4463b507067e9bedc573fe2b7d0ef2c8de20d4bdb7f68efda63b7aff4bb', '23adc524-be19-4e78-a7b2-ce9fd6e3f197', '2026-11-26 13:46:50', '2026-10-27 13:48:42', NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 13:46:50'),
(29, 3, 'f0e7792156bd188e1a94ee7308cfed1a21f764f1fd4f06db1c59961bfb1c347c', 'a6b2963b-333b-464b-9d0d-6b97d2292779', '2026-11-26 13:48:49', '2026-10-27 13:49:10', NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 13:48:49'),
(30, 1, 'ee638c942ef791e5d93dbed18e6f28f985f4edb5ad69c6fba8e267bcdd38801f', '748d151e-46be-43a5-9e4e-66d461693124', '2026-11-26 13:49:24', '2026-10-27 17:07:14', 32, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 13:49:24'),
(31, 1, '33d2732338659b82d27a1041b577b406e4ca5407c098ed5ac156031b8e55d6f9', '34a5a7cd-0003-477c-8e21-7ce9751ccfbe', '2026-11-26 17:04:52', NULL, NULL, '39.46.176.84', 'vscode-restclient', '2026-10-27 17:04:52'),
(32, 1, 'fb7148a0a4a190bd9ec5be0d0051ae4eba367f0f7d019afa5c34e6d669455a02', '748d151e-46be-43a5-9e4e-66d461693124', '2026-11-26 17:07:14', '2026-10-27 17:09:58', 33, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 17:07:14'),
(33, 1, 'bb953fef5cc608b861723210608e76701c1df83ea4a8de552a619a36605436ff', '748d151e-46be-43a5-9e4e-66d461693124', '2026-11-26 17:09:58', '2026-10-27 17:10:05', 34, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 17:09:58'),
(34, 1, 'ef87f7502b09275254a267940d7cb3d7e090dbce1bc749b577ca1627adf38342', '748d151e-46be-43a5-9e4e-66d461693124', '2026-11-26 17:10:05', '2026-10-27 17:10:16', 35, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 17:10:05'),
(35, 1, '12d2de29b6e7d4c364153c80f3424a05efa3c09d8d487dce7f7cc059725c819b', '748d151e-46be-43a5-9e4e-66d461693124', '2026-11-26 17:10:16', NULL, NULL, '39.46.176.84', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36', '2026-10-27 17:10:16');

-- --------------------------------------------------------

--
-- Table structure for table `reimbursements`
--

CREATE TABLE `reimbursements` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `person_user_id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL COMMENT 'The payment back to the person',
  `amount` bigint(20) NOT NULL COMMENT 'PKR paisa',
  `note` varchar(255) DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `reimbursement_items`
--

CREATE TABLE `reimbursement_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `reimbursement_id` bigint(20) UNSIGNED NOT NULL,
  `covered_transaction_id` bigint(20) UNSIGNED NOT NULL,
  `amount` bigint(20) NOT NULL COMMENT 'PKR paisa. May be part of the covered cost'
) ;

-- --------------------------------------------------------

--
-- Table structure for table `schema_migrations`
--

CREATE TABLE `schema_migrations` (
  `filename` varchar(190) NOT NULL,
  `applied_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `checksum` char(64) DEFAULT NULL COMMENT 'SHA-256 of the file. Set by the local runner, null when applied through phpMyAdmin'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `schema_migrations`
--

INSERT INTO `schema_migrations` (`filename`, `applied_at`, `checksum`) VALUES
('000_schema_migrations.sql', '2026-10-03 05:59:36', NULL),
('001_phase0_tables.sql', '2026-10-03 06:00:27', NULL),
('002_seed_reference.sql', '2026-10-03 06:00:49', NULL),
('003_bootstrap.sql', '2026-10-03 06:01:51', NULL),
('004_phase1_tables.sql', '2026-10-03 06:02:42', NULL),
('005_flag_resolution.sql', '2026-10-26 12:12:44', NULL),
('006_idempotency_request_hash.sql', '2026-10-27 02:18:08', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `sequences`
--

CREATE TABLE `sequences` (
  `name` varchar(50) NOT NULL COMMENT 'journal, invoice, quotation, receipt, voucher',
  `prefix` varchar(10) NOT NULL DEFAULT '',
  `next_value` bigint(20) UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Allocated with SELECT ... FOR UPDATE inside the caller transaction, so a rollback leaves no gap'
) ;

--
-- Dumping data for table `sequences`
--

INSERT INTO `sequences` (`name`, `prefix`, `next_value`) VALUES
('invoice', 'INV-', 5026),
('journal', 'JV-', 13),
('quotation', 'QT-', 1),
('receipt', 'RC-', 1),
('voucher', 'PV-', 1);

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `setting_key` varchar(100) NOT NULL COMMENT 'Not named key, which is a reserved word',
  `value` text DEFAULT NULL,
  `value_type` enum('string','int','bool','date','json') NOT NULL DEFAULT 'string',
  `description` varchar(255) NOT NULL DEFAULT '',
  `updated_by` bigint(20) UNSIGNED DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`setting_key`, `value`, `value_type`, `description`, `updated_by`, `updated_at`) VALUES
('atl_status', 'active', 'string', 'Winibex own status. Used only when tax is deducted from Winibex', NULL, '2026-10-03 06:00:49'),
('base_currency', 'PKR', 'string', 'Books are kept in this currency', NULL, '2026-10-03 06:00:49'),
('books_live_from', '2026-07-01', 'date', 'First date of live entry. Earlier dates are historical', NULL, '2026-10-03 06:00:49'),
('fiscal_year_start_month', '7', 'int', 'July to June, matching the Pakistan tax year', NULL, '2026-10-03 06:00:49'),
('fx_deviation_warning_percent', '5', 'int', 'Warn if a rate is this far from the last one used', NULL, '2026-10-03 06:00:49'),
('history_merged', 'false', 'bool', 'True once history reconciles and the opening entry is reversed', NULL, '2026-10-03 06:00:49'),
('large_cash_warning_above', '5000000', 'int', 'Paisa. 50,000 PKR', NULL, '2026-10-03 06:00:49'),
('next_invoice_number', '5026', 'int', 'Reference only. Allocation comes from the sequences table', NULL, '2026-10-03 06:00:49'),
('pass_through_max_days', '14', 'int', 'Flag money sitting in a personal account longer than this', NULL, '2026-10-03 06:00:49'),
('payroll_visible_to_all', 'true', 'bool', 'Permissive now, can be restricted later', NULL, '2026-10-03 06:00:49'),
('petty_cash_imprest', '2000000', 'int', 'Paisa. Target float, set by the admin', NULL, '2026-10-27 03:20:45'),
('pra_registered', 'false', 'bool', 'Not registered with the Punjab Revenue Authority', NULL, '2026-10-03 06:00:49'),
('pseb_registered', 'true', 'bool', 'Drives the Section 154A suggestion', NULL, '2026-10-03 06:00:49'),
('receipt_required_above', '500000', 'int', 'Paisa. 5,000 PKR', NULL, '2026-10-03 06:00:49');

-- --------------------------------------------------------

--
-- Table structure for table `taxes`
--

CREATE TABLE `taxes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL COMMENT 'Section 154A IT export final tax',
  `short_code` varchar(20) NOT NULL COMMENT 'Shown on documents',
  `authority` enum('fbr','pra','srb','ict','bank','other') NOT NULL,
  `law_reference` varchar(50) DEFAULT NULL COMMENT 'ITO 2001 s.154A',
  `kind` enum('withholding','final','advance','sales_tax','fed','other') NOT NULL,
  `applies_to` enum('sales','purchases','both') NOT NULL,
  `computation` enum('percent','fixed') NOT NULL DEFAULT 'percent',
  `rate_atl` decimal(9,4) NOT NULL COMMENT 'Rate when the party the tax is about is on the Active Taxpayers List',
  `rate_non_atl` decimal(9,4) NOT NULL,
  `status_basis` enum('company','counterparty') NOT NULL COMMENT 'company when tax is deducted from Winibex, counterparty when Winibex deducts. Decision 030',
  `return_section` varchar(20) DEFAULT NULL COMMENT 'Section code used in the s.165 statement',
  `is_inclusive` tinyint(1) NOT NULL DEFAULT 0,
  `is_adjustable` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Creditable later, as opposed to a final cost',
  `coa_id` bigint(20) UNSIGNED NOT NULL COMMENT 'Ledger account this tax posts to',
  `effective_from` date NOT NULL,
  `effective_to` date DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `notes` text DEFAULT NULL COMMENT 'Conditions such as PSEB registration or ATL',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `taxes`
--

INSERT INTO `taxes` (`id`, `name`, `short_code`, `authority`, `law_reference`, `kind`, `applies_to`, `computation`, `rate_atl`, `rate_non_atl`, `status_basis`, `return_section`, `is_inclusive`, `is_adjustable`, `coa_id`, `effective_from`, `effective_to`, `is_active`, `notes`, `created_at`, `updated_at`) VALUES
(1, 'TEST card advance tax', 'TEST-236Y', 'fbr', 'ITO 2001 s.236Y', 'advance', 'purchases', 'percent', 0.5000, 1.0000, 'company', NULL, 0, 1, 22, '2026-07-01', NULL, 1, 'Dummy rate for the Phase 1 test. Not a real seed.', '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(2, 'TEST export final tax', 'TEST-154A', 'fbr', 'ITO 2001 s.154A', 'final', 'sales', 'percent', 1.0000, 2.0000, 'company', NULL, 0, 0, 94, '2026-07-01', NULL, 1, 'Dummy rate for the Phase 1 test. Not a real seed.', '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(3, 'TEST withholding on services', 'TEST-153', 'fbr', 'ITO 2001 s.153', 'withholding', 'purchases', 'percent', 4.0000, 8.0000, 'counterparty', NULL, 0, 0, 47, '2026-07-01', NULL, 1, 'Dummy rate for the Phase 1 test. Not a real seed.', '2026-10-27 03:20:45', '2026-10-27 03:20:45');

-- --------------------------------------------------------

--
-- Table structure for table `tax_rules`
--

CREATE TABLE `tax_rules` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `tax_id` bigint(20) UNSIGNED NOT NULL,
  `direction` enum('in','out') NOT NULL,
  `currency_is_foreign` tinyint(1) DEFAULT NULL COMMENT 'NULL means the rule applies either way',
  `account_type` enum('bank','cash','petty_cash','cheque','pass_through') DEFAULT NULL,
  `category_id` bigint(20) UNSIGNED DEFAULT NULL,
  `client_country` varchar(60) DEFAULT NULL,
  `priority` int(11) NOT NULL DEFAULT 100 COMMENT 'Lower number is matched first',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tax_rules`
--

INSERT INTO `tax_rules` (`id`, `name`, `tax_id`, `direction`, `currency_is_foreign`, `account_type`, `category_id`, `client_country`, `priority`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'TEST foreign card payment', 1, 'out', 1, NULL, NULL, NULL, 10, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(2, 'TEST foreign client receipt', 2, 'in', 1, NULL, NULL, NULL, 10, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(3, 'TEST outsourcing withholding', 3, 'out', 0, NULL, 14, NULL, 20, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `journal_number` varchar(20) DEFAULT NULL COMMENT 'From sequences, at posting. Null while draft or pending',
  `date` date NOT NULL COMMENT 'Date of payment, not the date it was entered',
  `account_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'The company account the money moved on. Null when none did: paid by a person, the opening entry, a manual journal entry',
  `direction` enum('in','out') NOT NULL COMMENT 'Direction carries the sign. Amounts are never negative',
  `amount` bigint(20) NOT NULL COMMENT 'PKR paisa. Net effect on the account, the figure balances use',
  `currency` char(3) NOT NULL DEFAULT 'PKR',
  `foreign_amount` bigint(20) DEFAULT NULL COMMENT 'Minor units of the foreign currency. Null for PKR',
  `fx_rate` decimal(18,6) DEFAULT NULL COMMENT 'PKR per one unit of the foreign currency',
  `fx_rate_source` enum('manual','bank_advice','derived') DEFAULT NULL,
  `method` enum('cash','account','card','cheque','online') NOT NULL,
  `description` varchar(255) NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `client_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'No FK until Phase 2 creates clients',
  `project_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'No FK until Phase 2 creates projects',
  `is_rebillable` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Recovered from the client, so it posts to an asset not an expense',
  `rebilled_invoice_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'No FK until Phase 3 creates invoices',
  `fund_source` enum('operations','investor') NOT NULL DEFAULT 'operations',
  `paid_by_type` enum('company','person') NOT NULL DEFAULT 'company',
  `paid_by_user_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Set when a person paid personally. The company then owes them',
  `received_by_user_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Set when money landed with a person',
  `vendor_id` bigint(20) UNSIGNED DEFAULT NULL,
  `cheque_id` bigint(20) UNSIGNED DEFAULT NULL,
  `gross_amount` bigint(20) NOT NULL COMMENT 'PKR paisa before taxes and charges',
  `tax_total` bigint(20) NOT NULL DEFAULT 0,
  `charges_total` bigint(20) NOT NULL DEFAULT 0,
  `withheld_total` bigint(20) NOT NULL DEFAULT 0 COMMENT 'Tax Winibex deducted from the payee and owes FBR. Reduces the payment rather than adding to it. The figure the quarterly s.165 statement reports',
  `reference` varchar(50) DEFAULT NULL COMMENT 'Cheque or voucher number',
  `transfer_group_id` char(36) DEFAULT NULL COMMENT 'Links the two legs of a transfer',
  `status` enum('draft','pending','posted','rejected','reversed') NOT NULL DEFAULT 'draft',
  `entry_type` enum('normal','opening','historical','journal') NOT NULL DEFAULT 'normal' COMMENT 'journal is the manual entry that fits no guided form: depreciation, FX revaluation, year end',
  `rejection_reason` varchar(255) DEFAULT NULL,
  `reversal_of_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'This entry reverses that one',
  `reversed_by_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'That entry reverses this one',
  `reversal_reason` varchar(255) DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `approved_by` bigint(20) UNSIGNED DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `approval_method` enum('owner','admin','auto') DEFAULT NULL,
  `possible_self_approval` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Owner login approved an entry made by someone who shares it. Silent marker',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `journal_number`, `date`, `account_id`, `direction`, `amount`, `currency`, `foreign_amount`, `fx_rate`, `fx_rate_source`, `method`, `description`, `category_id`, `client_id`, `project_id`, `is_rebillable`, `rebilled_invoice_id`, `fund_source`, `paid_by_type`, `paid_by_user_id`, `received_by_user_id`, `vendor_id`, `cheque_id`, `gross_amount`, `tax_total`, `charges_total`, `withheld_total`, `reference`, `transfer_group_id`, `status`, `entry_type`, `rejection_reason`, `reversal_of_id`, `reversed_by_id`, `reversal_reason`, `created_by`, `approved_by`, `posted_at`, `approval_method`, `possible_self_approval`, `created_at`, `updated_at`) VALUES
(1, 'JV-1', '2026-07-01', NULL, 'in', 56000000, 'PKR', NULL, NULL, NULL, 'account', 'Opening balances at 30 June 2026 (TEST)', 13, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 56000000, 0, 0, 0, NULL, NULL, 'posted', 'opening', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 03:29:18', 'auto', 0, '2026-10-27 03:29:18', '2026-10-27 03:29:18'),
(2, 'JV-2', '2026-10-27', 2, 'out', 120000, 'PKR', NULL, NULL, NULL, 'account', 'Printer paper and pens', 27, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 120000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 12:03:13', 'auto', 0, '2026-10-27 12:03:12', '2026-10-27 12:03:13'),
(3, 'JV-3', '2026-10-27', 1, 'in', 15000000, 'PKR', NULL, NULL, NULL, 'account', 'Website project advance from test client ABC', 3, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 15000000, 0, 0, 0, NULL, NULL, 'reversed', 'normal', NULL, NULL, 13, NULL, 1, 1, '2026-10-27 12:04:09', 'auto', 0, '2026-10-27 12:04:08', '2026-10-27 17:05:50'),
(4, 'JV-4', '2026-10-27', 1, 'out', 560000, 'PKR', NULL, NULL, NULL, 'account', 'Claude Pro subscription October', 24, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 560000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 12:05:11', 'auto', 0, '2026-10-27 12:05:09', '2026-10-27 12:05:11'),
(5, 'JV-5', '2026-10-27', 1, 'out', 650000, 'PKR', NULL, NULL, NULL, 'account', 'Hostinger renewal', 25, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 650000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 13:41:54', 'auto', 0, '2026-10-27 13:41:11', '2026-10-27 13:41:54'),
(6, 'JV-6', '2026-10-27', 1, 'in', 14000000, 'USD', 50000, 280.000000, 'manual', 'account', 'Test export client invoice 1001', 1, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 14000000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 13:45:08', 'auto', 0, '2026-10-27 13:45:07', '2026-10-27 13:45:08'),
(7, 'JV-7', '2026-10-27', 3, 'out', 220000, 'PKR', NULL, NULL, NULL, 'account', 'Snacks for team meeting', 21, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 220000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, NULL, NULL, NULL, 4, 1, '2026-10-27 13:49:42', 'owner', 1, '2026-10-27 13:47:44', '2026-10-27 13:49:42'),
(8, NULL, '2026-10-27', 1, 'out', 1200000, 'PKR', NULL, NULL, NULL, 'account', 'Laptop screen repair', 28, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 1200000, 0, 0, 0, NULL, NULL, 'rejected', 'normal', 'Attach the repair invoice and resubmit', NULL, NULL, NULL, 4, NULL, NULL, NULL, 0, '2026-10-27 13:48:15', '2026-10-27 13:50:02'),
(9, 'JV-8', '2026-10-27', 1, 'out', 6005000, 'PKR', NULL, NULL, NULL, 'account', 'Cash withdrawal for office', 12, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 6000000, 0, 5000, 0, NULL, 'ff04fb5a-fb7e-4b5f-afcf-95c27a12d96b', 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 17:05:13', 'auto', 0, '2026-10-27 17:05:13', '2026-10-27 17:05:13'),
(10, 'JV-9', '2026-10-27', 2, 'in', 6000000, 'PKR', NULL, NULL, NULL, 'account', 'Cash withdrawal for office', 11, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 6000000, 0, 0, 0, NULL, 'ff04fb5a-fb7e-4b5f-afcf-95c27a12d96b', 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 17:05:13', 'auto', 0, '2026-10-27 17:05:13', '2026-10-27 17:05:13'),
(11, 'JV-10', '2026-10-27', 2, 'out', 500000, 'PKR', NULL, NULL, NULL, 'account', 'Petty cash top up', 12, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 500000, 0, 0, 0, NULL, '5a70591c-a151-4af1-b1aa-1f8c4df5c7ee', 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 17:05:24', 'auto', 0, '2026-10-27 17:05:24', '2026-10-27 17:05:24'),
(12, 'JV-11', '2026-10-27', 3, 'in', 500000, 'PKR', NULL, NULL, NULL, 'account', 'Petty cash top up', 11, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 500000, 0, 0, 0, NULL, '5a70591c-a151-4af1-b1aa-1f8c4df5c7ee', 'posted', 'normal', NULL, NULL, NULL, NULL, 1, 1, '2026-10-27 17:05:24', 'auto', 0, '2026-10-27 17:05:24', '2026-10-27 17:05:24'),
(13, 'JV-12', '2026-10-27', 1, 'out', 15000000, 'PKR', NULL, NULL, NULL, 'account', 'Reversal of JV-3: Test reversal, wrong client', 3, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 15000000, 0, 0, 0, NULL, NULL, 'posted', 'normal', NULL, 3, NULL, 'Test reversal, wrong client', 1, 1, '2026-10-27 17:05:50', 'owner', 0, '2026-10-27 17:05:50', '2026-10-27 17:05:50'),
(14, NULL, '2026-10-27', 3, 'out', 80000, 'PKR', NULL, NULL, NULL, 'cash', 'Idempotency test, should exist once', 27, NULL, NULL, 0, NULL, 'operations', 'company', NULL, NULL, NULL, NULL, 80000, 0, 0, 0, NULL, NULL, 'draft', 'normal', NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 0, '2026-10-27 17:06:48', '2026-10-27 17:06:48');

--
-- Triggers `transactions`
--
DELIMITER $$
CREATE TRIGGER `trg_transactions_immutable` BEFORE UPDATE ON `transactions` FOR EACH ROW BEGIN
  IF OLD.status IN ('posted', 'reversed') THEN

    IF NOT (
         NEW.journal_number         <=> OLD.journal_number
     AND NEW.date                   <=> OLD.date
     AND NEW.account_id             <=> OLD.account_id
     AND NEW.direction              <=> OLD.direction
     AND NEW.amount                 <=> OLD.amount
     AND NEW.currency               <=> OLD.currency
     AND NEW.foreign_amount         <=> OLD.foreign_amount
     AND NEW.fx_rate                <=> OLD.fx_rate
     AND NEW.fx_rate_source         <=> OLD.fx_rate_source
     AND NEW.method                 <=> OLD.method
     AND NEW.description            <=> OLD.description
     AND NEW.category_id            <=> OLD.category_id
     AND NEW.client_id              <=> OLD.client_id
     AND NEW.project_id             <=> OLD.project_id
     AND NEW.is_rebillable          <=> OLD.is_rebillable
     AND NEW.fund_source            <=> OLD.fund_source
     AND NEW.paid_by_type           <=> OLD.paid_by_type
     AND NEW.paid_by_user_id        <=> OLD.paid_by_user_id
     AND NEW.received_by_user_id    <=> OLD.received_by_user_id
     AND NEW.vendor_id              <=> OLD.vendor_id
     AND NEW.cheque_id              <=> OLD.cheque_id
     AND NEW.gross_amount           <=> OLD.gross_amount
     AND NEW.tax_total              <=> OLD.tax_total
     AND NEW.charges_total          <=> OLD.charges_total
     AND NEW.reference              <=> OLD.reference
     AND NEW.transfer_group_id      <=> OLD.transfer_group_id
     AND NEW.entry_type             <=> OLD.entry_type
     AND NEW.rejection_reason       <=> OLD.rejection_reason
     AND NEW.reversal_of_id         <=> OLD.reversal_of_id
     AND NEW.reversal_reason        <=> OLD.reversal_reason
     AND NEW.created_by             <=> OLD.created_by
     AND NEW.approved_by            <=> OLD.approved_by
     AND NEW.posted_at              <=> OLD.posted_at
     AND NEW.approval_method        <=> OLD.approval_method
     AND NEW.possible_self_approval <=> OLD.possible_self_approval
     AND NEW.created_at             <=> OLD.created_at
    ) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Posted entries are immutable. Reverse and re-enter instead.';
    END IF;

    -- The only status move allowed after posting.
    IF NOT (NEW.status <=> OLD.status)
       AND NOT (OLD.status = 'posted' AND NEW.status = 'reversed') THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A posted entry may only move to reversed.';
    END IF;

    -- reversed_by_id is written once, by the reversal.
    IF NOT (NEW.reversed_by_id <=> OLD.reversed_by_id)
       AND OLD.reversed_by_id IS NOT NULL THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'An entry is reversed once. Its reversal cannot be changed.';
    END IF;

  END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_transactions_no_delete` BEFORE DELETE ON `transactions` FOR EACH ROW BEGIN
  SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Transactions are never deleted. Reverse the entry instead.';
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `transaction_charges`
--

CREATE TABLE `transaction_charges` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('bank_charge','forex_fee','platform_fee','card_fee','other') NOT NULL,
  `amount` bigint(20) NOT NULL COMMENT 'PKR paisa',
  `coa_id` bigint(20) UNSIGNED NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

--
-- Dumping data for table `transaction_charges`
--

INSERT INTO `transaction_charges` (`id`, `transaction_id`, `type`, `amount`, `coa_id`, `note`, `created_at`) VALUES
(1, 9, 'bank_charge', 5000, 90, 'Transfer fee', '2026-10-27 17:05:13');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_taxes`
--

CREATE TABLE `transaction_taxes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `transaction_id` bigint(20) UNSIGNED NOT NULL,
  `tax_id` bigint(20) UNSIGNED NOT NULL,
  `base_amount` bigint(20) NOT NULL COMMENT 'PKR paisa the rate was applied to',
  `rate_applied` decimal(9,4) NOT NULL COMMENT 'Snapshot of the rate used',
  `atl_status_used` enum('atl','non_atl') NOT NULL,
  `atl_party` enum('company','vendor','client','employee','cardholder') NOT NULL COMMENT 'Whose status decided the rate. Decision 030',
  `tax_amount` bigint(20) NOT NULL COMMENT 'PKR paisa',
  `is_override` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'User changed it from the configured rate',
  `deducted_by` enum('bank','customer','us','platform') NOT NULL,
  `statement_id` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'No FK until Phase 6 creates withholding_statements',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL COMMENT 'The algorithm is readable from the value itself, so it can change without locking anyone out',
  `must_change_password` tinyint(1) NOT NULL DEFAULT 0,
  `role` enum('owner','admin','staff') NOT NULL,
  `approval_limit` bigint(20) UNSIGNED DEFAULT NULL COMMENT 'Paisa. Admins only. Null means unlimited',
  `auto_approve_own` tinyint(1) NOT NULL DEFAULT 0,
  `shares_owner_login` tinyint(1) NOT NULL DEFAULT 0 COMMENT 'Set for people who also use the winibexoffice login',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'A user is deactivated, never deleted',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `owner_singleton` tinyint(3) UNSIGNED GENERATED ALWAYS AS (case when `role` = 'owner' then 1 end) STORED
) ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `must_change_password`, `role`, `approval_limit`, `auto_approve_own`, `shares_owner_login`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Winibex office', 'winibexoffice@gmail.com', '$2b$12$1jce5CpZyV.LZamNWLYiuuzBfoCFmOhQy7tE9mhxyAjDIOYHUKkpm', 0, 'owner', NULL, 0, 0, 1, '2026-10-03 06:01:51', '2026-10-04 05:04:30'),
(2, 'Test Admin', 'admin@winibex.test', '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny', 0, 'admin', NULL, 0, 0, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(3, 'Test Limited Admin', 'limited@winibex.test', '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny', 0, 'admin', 1000000, 1, 0, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45'),
(4, 'Test Staff', 'staff@winibex.test', '$2a$12$B/QTRIIZGCYXFTu5AXa75.rBZ13keJVQxB4doy4W9dXR8kEL9ygny', 0, 'staff', NULL, 0, 1, 1, '2026-10-27 03:20:45', '2026-10-27 03:20:45');

-- --------------------------------------------------------

--
-- Table structure for table `vendors`
--

CREATE TABLE `vendors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(150) NOT NULL,
  `kind` enum('company','aop','individual','foreign') NOT NULL,
  `ntn` varchar(20) DEFAULT NULL,
  `cnic` varchar(20) DEFAULT NULL,
  `strn` varchar(20) DEFAULT NULL,
  `atl_status` enum('atl','non_atl','unknown') NOT NULL DEFAULT 'unknown',
  `atl_checked_on` date DEFAULT NULL COMMENT 'Warned about when older than 30 days at payment time',
  `default_tax_id` bigint(20) UNSIGNED DEFAULT NULL,
  `country` varchar(60) DEFAULT NULL,
  `email` varchar(190) DEFAULT NULL,
  `phone` varchar(40) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_accounts_name` (`name`),
  ADD UNIQUE KEY `uq_accounts_coa` (`coa_id`) COMMENT 'One ledger code per account, or a balance belongs to two places at once',
  ADD KEY `fk_accounts_owner` (`owner_user_id`);

--
-- Indexes for table `attachments`
--
ALTER TABLE `attachments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_attachments_transaction` (`transaction_id`,`document_type`),
  ADD KEY `fk_attachments_uploaded_by` (`uploaded_by`);

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_audit_log_record` (`table_name`,`record_id`,`created_at`),
  ADD KEY `idx_audit_log_user` (`user_id`,`created_at`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_categories_name` (`name`),
  ADD KEY `idx_categories_head` (`main_head`,`direction`,`is_active`),
  ADD KEY `fk_categories_coa` (`coa_id`);

--
-- Indexes for table `chart_of_accounts`
--
ALTER TABLE `chart_of_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_chart_of_accounts_code` (`code`),
  ADD KEY `idx_chart_of_accounts_type` (`type`,`code`),
  ADD KEY `fk_chart_of_accounts_parent` (`parent_id`),
  ADD KEY `fk_chart_of_accounts_return_head` (`fbr_return_head_code`);

--
-- Indexes for table `cheques`
--
ALTER TABLE `cheques`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_cheques_account_number` (`account_id`,`cheque_number`),
  ADD KEY `fk_cheques_created_by` (`created_by`),
  ADD KEY `fk_cheques_transaction` (`transaction_id`);

--
-- Indexes for table `company_profile`
--
ALTER TABLE `company_profile`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `currencies`
--
ALTER TABLE `currencies`
  ADD PRIMARY KEY (`code`);

--
-- Indexes for table `entry_flags`
--
ALTER TABLE `entry_flags`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_entry_flags_review` (`resolved`,`severity`),
  ADD KEY `fk_entry_flags_transaction` (`transaction_id`),
  ADD KEY `fk_entry_flags_acknowledged_by` (`acknowledged_by`),
  ADD KEY `fk_entry_flags_resolved_by` (`resolved_by`);

--
-- Indexes for table `fbr_return_heads`
--
ALTER TABLE `fbr_return_heads`
  ADD PRIMARY KEY (`code`);

--
-- Indexes for table `idempotency_keys`
--
ALTER TABLE `idempotency_keys`
  ADD PRIMARY KEY (`idempotency_key`),
  ADD KEY `idx_idempotency_keys_expiry` (`created_at`),
  ADD KEY `fk_idempotency_keys_user` (`user_id`);

--
-- Indexes for table `journal_lines`
--
ALTER TABLE `journal_lines`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_journal_lines_order` (`transaction_id`,`line_no`),
  ADD KEY `idx_journal_lines_coa` (`coa_id`,`transaction_id`);

--
-- Indexes for table `period_locks`
--
ALTER TABLE `period_locks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_period_locks` (`period_year`,`period_month`),
  ADD KEY `fk_period_locks_user` (`locked_by`);

--
-- Indexes for table `refresh_tokens`
--
ALTER TABLE `refresh_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_refresh_tokens_hash` (`token_hash`),
  ADD KEY `idx_refresh_tokens_family` (`family_id`,`revoked_at`),
  ADD KEY `idx_refresh_tokens_user` (`user_id`,`expires_at`),
  ADD KEY `fk_refresh_tokens_replaced_by` (`replaced_by_id`);

--
-- Indexes for table `reimbursements`
--
ALTER TABLE `reimbursements`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_reimbursements_transaction` (`transaction_id`),
  ADD KEY `fk_reimbursements_person` (`person_user_id`),
  ADD KEY `fk_reimbursements_created_by` (`created_by`);

--
-- Indexes for table `reimbursement_items`
--
ALTER TABLE `reimbursement_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_reimbursement_items` (`reimbursement_id`,`covered_transaction_id`),
  ADD KEY `fk_reimbursement_items_transaction` (`covered_transaction_id`);

--
-- Indexes for table `schema_migrations`
--
ALTER TABLE `schema_migrations`
  ADD PRIMARY KEY (`filename`);

--
-- Indexes for table `sequences`
--
ALTER TABLE `sequences`
  ADD PRIMARY KEY (`name`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`setting_key`),
  ADD KEY `fk_settings_updated_by` (`updated_by`);

--
-- Indexes for table `taxes`
--
ALTER TABLE `taxes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_taxes_code_from` (`short_code`,`effective_from`),
  ADD KEY `fk_taxes_coa` (`coa_id`);

--
-- Indexes for table `tax_rules`
--
ALTER TABLE `tax_rules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_tax_rules_tax` (`tax_id`),
  ADD KEY `fk_tax_rules_category` (`category_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_transactions_journal_number` (`journal_number`),
  ADD UNIQUE KEY `uq_transactions_reversal_of` (`reversal_of_id`) COMMENT 'An entry can be reversed once',
  ADD UNIQUE KEY `uq_transactions_reversed_by` (`reversed_by_id`),
  ADD KEY `idx_transactions_account_status_date` (`account_id`,`status`,`date`),
  ADD KEY `idx_transactions_client_date` (`client_id`,`date`),
  ADD KEY `idx_transactions_status_created` (`status`,`created_at`) COMMENT 'The approval inbox',
  ADD KEY `idx_transactions_date` (`date`),
  ADD KEY `idx_transactions_transfer_group` (`transfer_group_id`),
  ADD KEY `fk_transactions_currency` (`currency`),
  ADD KEY `fk_transactions_category` (`category_id`),
  ADD KEY `fk_transactions_paid_by` (`paid_by_user_id`),
  ADD KEY `fk_transactions_received_by` (`received_by_user_id`),
  ADD KEY `fk_transactions_vendor` (`vendor_id`),
  ADD KEY `fk_transactions_cheque` (`cheque_id`),
  ADD KEY `fk_transactions_created_by` (`created_by`),
  ADD KEY `fk_transactions_approved_by` (`approved_by`);

--
-- Indexes for table `transaction_charges`
--
ALTER TABLE `transaction_charges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_transaction_charges_transaction` (`transaction_id`),
  ADD KEY `fk_transaction_charges_coa` (`coa_id`);

--
-- Indexes for table `transaction_taxes`
--
ALTER TABLE `transaction_taxes`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_transaction_taxes_statement` (`tax_id`,`statement_id`),
  ADD KEY `fk_transaction_taxes_transaction` (`transaction_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD UNIQUE KEY `uq_users_single_owner` (`owner_singleton`);

--
-- Indexes for table `vendors`
--
ALTER TABLE `vendors`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_vendors_name` (`name`),
  ADD KEY `fk_vendors_tax` (`default_tax_id`),
  ADD KEY `fk_vendors_created_by` (`created_by`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attachments`
--
ALTER TABLE `attachments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT for table `chart_of_accounts`
--
ALTER TABLE `chart_of_accounts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cheques`
--
ALTER TABLE `cheques`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `entry_flags`
--
ALTER TABLE `entry_flags`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `journal_lines`
--
ALTER TABLE `journal_lines`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `period_locks`
--
ALTER TABLE `period_locks`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `refresh_tokens`
--
ALTER TABLE `refresh_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `reimbursements`
--
ALTER TABLE `reimbursements`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reimbursement_items`
--
ALTER TABLE `reimbursement_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `taxes`
--
ALTER TABLE `taxes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tax_rules`
--
ALTER TABLE `tax_rules`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaction_charges`
--
ALTER TABLE `transaction_charges`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transaction_taxes`
--
ALTER TABLE `transaction_taxes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendors`
--
ALTER TABLE `vendors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `accounts`
--
ALTER TABLE `accounts`
  ADD CONSTRAINT `fk_accounts_coa` FOREIGN KEY (`coa_id`) REFERENCES `chart_of_accounts` (`id`),
  ADD CONSTRAINT `fk_accounts_owner` FOREIGN KEY (`owner_user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `attachments`
--
ALTER TABLE `attachments`
  ADD CONSTRAINT `fk_attachments_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`),
  ADD CONSTRAINT `fk_attachments_uploaded_by` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD CONSTRAINT `fk_audit_log_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `fk_categories_coa` FOREIGN KEY (`coa_id`) REFERENCES `chart_of_accounts` (`id`);

--
-- Constraints for table `chart_of_accounts`
--
ALTER TABLE `chart_of_accounts`
  ADD CONSTRAINT `fk_chart_of_accounts_parent` FOREIGN KEY (`parent_id`) REFERENCES `chart_of_accounts` (`id`),
  ADD CONSTRAINT `fk_chart_of_accounts_return_head` FOREIGN KEY (`fbr_return_head_code`) REFERENCES `fbr_return_heads` (`code`);

--
-- Constraints for table `cheques`
--
ALTER TABLE `cheques`
  ADD CONSTRAINT `fk_cheques_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_cheques_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_cheques_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `entry_flags`
--
ALTER TABLE `entry_flags`
  ADD CONSTRAINT `fk_entry_flags_acknowledged_by` FOREIGN KEY (`acknowledged_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_entry_flags_resolved_by` FOREIGN KEY (`resolved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_entry_flags_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `idempotency_keys`
--
ALTER TABLE `idempotency_keys`
  ADD CONSTRAINT `fk_idempotency_keys_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `journal_lines`
--
ALTER TABLE `journal_lines`
  ADD CONSTRAINT `fk_journal_lines_coa` FOREIGN KEY (`coa_id`) REFERENCES `chart_of_accounts` (`id`),
  ADD CONSTRAINT `fk_journal_lines_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `period_locks`
--
ALTER TABLE `period_locks`
  ADD CONSTRAINT `fk_period_locks_user` FOREIGN KEY (`locked_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `refresh_tokens`
--
ALTER TABLE `refresh_tokens`
  ADD CONSTRAINT `fk_refresh_tokens_replaced_by` FOREIGN KEY (`replaced_by_id`) REFERENCES `refresh_tokens` (`id`),
  ADD CONSTRAINT `fk_refresh_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `reimbursements`
--
ALTER TABLE `reimbursements`
  ADD CONSTRAINT `fk_reimbursements_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_reimbursements_person` FOREIGN KEY (`person_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_reimbursements_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `reimbursement_items`
--
ALTER TABLE `reimbursement_items`
  ADD CONSTRAINT `fk_reimbursement_items_reimbursement` FOREIGN KEY (`reimbursement_id`) REFERENCES `reimbursements` (`id`),
  ADD CONSTRAINT `fk_reimbursement_items_transaction` FOREIGN KEY (`covered_transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `settings`
--
ALTER TABLE `settings`
  ADD CONSTRAINT `fk_settings_updated_by` FOREIGN KEY (`updated_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `taxes`
--
ALTER TABLE `taxes`
  ADD CONSTRAINT `fk_taxes_coa` FOREIGN KEY (`coa_id`) REFERENCES `chart_of_accounts` (`id`);

--
-- Constraints for table `tax_rules`
--
ALTER TABLE `tax_rules`
  ADD CONSTRAINT `fk_tax_rules_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  ADD CONSTRAINT `fk_tax_rules_tax` FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`);

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `fk_transactions_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`),
  ADD CONSTRAINT `fk_transactions_cheque` FOREIGN KEY (`cheque_id`) REFERENCES `cheques` (`id`),
  ADD CONSTRAINT `fk_transactions_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_transactions_currency` FOREIGN KEY (`currency`) REFERENCES `currencies` (`code`),
  ADD CONSTRAINT `fk_transactions_paid_by` FOREIGN KEY (`paid_by_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_transactions_received_by` FOREIGN KEY (`received_by_user_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_transactions_reversal_of` FOREIGN KEY (`reversal_of_id`) REFERENCES `transactions` (`id`),
  ADD CONSTRAINT `fk_transactions_reversed_by` FOREIGN KEY (`reversed_by_id`) REFERENCES `transactions` (`id`),
  ADD CONSTRAINT `fk_transactions_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`);

--
-- Constraints for table `transaction_charges`
--
ALTER TABLE `transaction_charges`
  ADD CONSTRAINT `fk_transaction_charges_coa` FOREIGN KEY (`coa_id`) REFERENCES `chart_of_accounts` (`id`),
  ADD CONSTRAINT `fk_transaction_charges_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `transaction_taxes`
--
ALTER TABLE `transaction_taxes`
  ADD CONSTRAINT `fk_transaction_taxes_tax` FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`),
  ADD CONSTRAINT `fk_transaction_taxes_transaction` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`);

--
-- Constraints for table `vendors`
--
ALTER TABLE `vendors`
  ADD CONSTRAINT `fk_vendors_created_by` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `fk_vendors_tax` FOREIGN KEY (`default_tax_id`) REFERENCES `taxes` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
