-- 002_seed_reference
--
-- Reference data that is the same for any installation: currencies, the chart
-- of accounts, the categories that map onto it, settings and sequences.
--
-- Company-specific data (profile, users, real bank accounts) is 003.
-- Taxes are deliberately NOT seeded. They wait for the accountant.
--
-- The chart follows docs/CHART-OF-ACCOUNTS.md. It is a draft until the
-- accountant signs it off.

-- ---------------------------------------------------------------------------
-- Currencies
-- ---------------------------------------------------------------------------

INSERT INTO currencies (code, name, symbol, minor_units, is_active) VALUES
  ('PKR', 'Pakistani Rupee',       'Rs',  2, 1),
  ('USD', 'US Dollar',             '$',   2, 1),
  ('GBP', 'Pound Sterling',        '£',   2, 1),
  ('EUR', 'Euro',                  '€',   2, 1),
  ('AED', 'UAE Dirham',            'AED', 2, 1),
  ('QAR', 'Qatari Riyal',          'QAR', 2, 1);

-- ---------------------------------------------------------------------------
-- Chart of accounts
--
-- is_header         grouping only, never posted to by any path
-- is_system         cannot be renamed or deactivated
-- allow_manual_posting = 0 marks a control account, written only by its own
--                      module, never by a hand-written journal entry
-- ---------------------------------------------------------------------------

INSERT INTO chart_of_accounts
  (code, name, type, normal_balance, is_header, is_system, allow_manual_posting) VALUES

  -- 1000 Assets
  ('1000', 'Assets',                              'asset', 'debit',  1, 1, 0),
  ('1100', 'Current assets',                      'asset', 'debit',  1, 1, 0),
  ('1110', 'Cash and cash equivalents',           'asset', 'debit',  1, 1, 0),
  ('1111', 'Cash in hand, office',                'asset', 'debit',  0, 1, 1),
  ('1112', 'Petty cash',                          'asset', 'debit',  0, 1, 1),
  ('1113', 'Bank, Winibex current account',       'asset', 'debit',  0, 1, 1),
  ('1114', 'Cheques in hand, uncleared',          'asset', 'debit',  0, 0, 1),
  ('1115', 'Funds in transit, Fazal',             'asset', 'debit',  0, 1, 1),
  ('1116', 'Funds in transit, Ahmad',             'asset', 'debit',  0, 1, 1),
  ('1117', 'Funds held on platforms',             'asset', 'debit',  0, 0, 1),

  ('1120', 'Trade receivables',                   'asset', 'debit',  1, 1, 0),
  ('1121', 'Trade receivables, local',            'asset', 'debit',  0, 1, 0),
  ('1122', 'Trade receivables, foreign',          'asset', 'debit',  0, 1, 0),
  ('1123', 'Rebillable expenses recoverable',     'asset', 'debit',  0, 1, 0),

  ('1130', 'Advances, deposits and prepayments',  'asset', 'debit',  1, 1, 0),
  ('1131', 'Advances to employees',               'asset', 'debit',  0, 0, 1),
  ('1132', 'Advances to suppliers',               'asset', 'debit',  0, 0, 1),
  ('1133', 'Prepaid expenses',                    'asset', 'debit',  0, 0, 1),
  ('1134', 'Security deposits',                   'asset', 'debit',  0, 0, 1),

  ('1140', 'Tax assets',                          'asset', 'debit',  1, 1, 0),
  ('1141', 'Advance income tax, adjustable',      'asset', 'debit',  0, 1, 1),
  ('1142', 'Income tax withheld by customers',    'asset', 'debit',  0, 1, 1),
  ('1143', 'Sales tax input, PRA',                'asset', 'debit',  0, 0, 1),

  ('1200', 'Non-current assets',                  'asset', 'debit',  1, 1, 0),
  ('1210', 'Property and equipment',              'asset', 'debit',  1, 1, 0),
  ('1211', 'Computers and IT equipment',          'asset', 'debit',  0, 0, 1),
  ('1212', 'Furniture and fixtures',              'asset', 'debit',  0, 0, 1),
  ('1213', 'Office equipment',                    'asset', 'debit',  0, 0, 1),
  ('1219', 'Accumulated depreciation',            'asset', 'credit', 0, 1, 0),

  ('1220', 'Intangible assets',                   'asset', 'debit',  1, 1, 0),
  ('1221', 'Software and licences',               'asset', 'debit',  0, 0, 1),
  ('1222', 'Website and domain',                  'asset', 'debit',  0, 0, 1),
  ('1229', 'Accumulated amortisation',            'asset', 'credit', 0, 1, 0),

  -- 2000 Liabilities
  ('2000', 'Liabilities',                         'liability', 'credit', 1, 1, 0),
  ('2100', 'Current liabilities',                 'liability', 'credit', 1, 1, 0),
  ('2110', 'Trade and other payables',            'liability', 'credit', 1, 1, 0),
  ('2111', 'Payable to suppliers',                'liability', 'credit', 0, 1, 0),
  ('2112', 'Payable to contractors',              'liability', 'credit', 0, 0, 1),
  ('2113', 'Accrued expenses',                    'liability', 'credit', 0, 0, 1),
  ('2114', 'Payable to employees, reimbursements','liability', 'credit', 0, 1, 0),
  ('2115', 'Partner share payable',               'liability', 'credit', 0, 1, 0),
  ('2120', 'Salaries payable',                    'liability', 'credit', 0, 1, 0),
  ('2140', 'Advances from customers',             'liability', 'credit', 0, 1, 1),

  ('2130', 'Tax liabilities',                     'liability', 'credit', 1, 1, 0),
  ('2131', 'Withholding payable, salaries (s.149)',          'liability', 'credit', 0, 1, 1),
  ('2132', 'Withholding payable, services and suppliers (s.153)', 'liability', 'credit', 0, 1, 1),
  ('2133', 'Sales tax payable, PRA',              'liability', 'credit', 0, 0, 1),
  ('2134', 'Income tax payable',                  'liability', 'credit', 0, 1, 1),

  ('2200', 'Non-current liabilities',             'liability', 'credit', 1, 1, 0),
  ('2210', 'Loan from director, Hammad Malik',    'liability', 'credit', 0, 0, 1),
  ('2220', 'Loans from other investors',          'liability', 'credit', 0, 0, 1),

  -- 3000 Equity
  ('3000', 'Equity',                              'equity', 'credit', 1, 1, 0),
  ('3100', 'Share capital',                       'equity', 'credit', 0, 1, 1),
  ('3200', 'Retained earnings or accumulated loss','equity', 'credit', 0, 1, 1),
  ('3300', 'Current year profit or loss',         'equity', 'credit', 0, 1, 0),
  ('3400', 'Opening balance equity',              'equity', 'credit', 0, 1, 0),

  -- 4000 Income
  ('4000', 'Income',                              'income', 'credit', 1, 1, 0),
  ('4110', 'Software and app development, export','income', 'credit', 0, 1, 1),
  ('4120', 'Digital marketing services, export',  'income', 'credit', 0, 1, 1),
  ('4210', 'Website development, local',          'income', 'credit', 0, 1, 1),
  ('4220', 'Social media and ads management, local', 'income', 'credit', 0, 1, 1),
  ('4230', 'Design services',                     'income', 'credit', 0, 0, 1),
  ('4310', 'Exchange gain',                       'income', 'credit', 0, 1, 1),
  ('4320', 'Bank profit',                         'income', 'credit', 0, 0, 1),

  -- 5000 Cost of services
  ('5000', 'Cost of services',                    'expense', 'debit', 1, 1, 0),
  ('5100', 'Outsourcing and subcontractors',      'expense', 'debit', 0, 0, 1),
  ('5200', 'Client advertising spend, absorbed',  'expense', 'debit', 0, 0, 1),
  ('5300', 'Project software and tools',          'expense', 'debit', 0, 0, 1),
  ('5400', 'Platform fees',                       'expense', 'debit', 0, 1, 1),
  ('5500', 'Partner profit share',                'expense', 'debit', 0, 1, 1),
  ('5600', 'Project travel',                      'expense', 'debit', 0, 0, 1),

  -- 6000 Administrative expenses
  ('6000', 'Administrative expenses',             'expense', 'debit', 1, 1, 0),
  ('6100', 'Salaries and wages',                  'expense', 'debit', 0, 1, 1),
  ('6110', 'Staff welfare',                       'expense', 'debit', 0, 0, 1),
  ('6200', 'Rent and utilities',                  'expense', 'debit', 0, 0, 1),
  ('6300', 'Telecommunication and internet',      'expense', 'debit', 0, 0, 1),
  ('6400', 'Software subscriptions',              'expense', 'debit', 0, 0, 1),
  ('6410', 'Hosting and domains',                 'expense', 'debit', 0, 0, 1),
  ('6500', 'Travelling and conveyance',           'expense', 'debit', 0, 0, 1),
  ('6600', 'Office supplies, printing and stationery', 'expense', 'debit', 0, 0, 1),
  ('6700', 'Repairs and maintenance',             'expense', 'debit', 0, 0, 1),
  ('6800', 'Legal, registration and professional fees', 'expense', 'debit', 0, 0, 1),
  ('6900', 'Entertainment',                       'expense', 'debit', 0, 0, 1),
  ('6950', 'Depreciation and amortisation',       'expense', 'debit', 0, 1, 0),

  -- 7000 Selling and marketing
  ('7000', 'Selling and marketing',               'expense', 'debit', 1, 1, 0),
  ('7100', 'Own advertising',                     'expense', 'debit', 0, 0, 1),
  ('7200', 'Business development',                'expense', 'debit', 0, 0, 1),

  -- 8000 Finance costs and other
  ('8000', 'Finance costs and other',             'expense', 'debit', 1, 1, 0),
  ('8100', 'Bank charges and FED',                'expense', 'debit', 0, 1, 1),
  ('8200', 'Forex and card fees',                 'expense', 'debit', 0, 1, 1),
  ('8300', 'Exchange loss',                       'expense', 'debit', 0, 1, 1),

  -- 9000 Taxation
  ('9000', 'Taxation',                            'expense', 'debit', 1, 1, 0),
  ('9100', 'Final tax, Section 154A',             'expense', 'debit', 0, 1, 1),
  ('9200', 'Current income tax, normal regime',   'expense', 'debit', 0, 1, 1),
  ('9300', 'Minimum tax',                         'expense', 'debit', 0, 1, 1);

-- Parent links, deepest first. Each account takes the nearest ancestor code
-- that exists and is a header: 1111 -> 1110, 2120 -> 2100, 6110 -> 6000.

UPDATE chart_of_accounts c
  JOIN chart_of_accounts p
    ON p.code = CONCAT(LEFT(c.code, 3), '0') AND p.is_header = 1 AND p.code <> c.code
SET c.parent_id = p.id
WHERE c.parent_id IS NULL;

UPDATE chart_of_accounts c
  JOIN chart_of_accounts p
    ON p.code = CONCAT(LEFT(c.code, 2), '00') AND p.is_header = 1 AND p.code <> c.code
SET c.parent_id = p.id
WHERE c.parent_id IS NULL;

UPDATE chart_of_accounts c
  JOIN chart_of_accounts p
    ON p.code = CONCAT(LEFT(c.code, 1), '000') AND p.is_header = 1 AND p.code <> c.code
SET c.parent_id = p.id
WHERE c.parent_id IS NULL;

-- ---------------------------------------------------------------------------
-- Categories, what a user picks on the entry form
-- ---------------------------------------------------------------------------

INSERT INTO categories (name, main_head, direction, coa_id)
SELECT seed.name, seed.main_head, seed.direction, coa.id
FROM (
  SELECT 'Software and app development, export' AS name, 'revenue' AS main_head, 'in' AS direction, '4110' AS code
  UNION ALL SELECT 'Digital marketing, export',            'revenue',       'in',  '4120'
  UNION ALL SELECT 'Website development, local',           'revenue',       'in',  '4210'
  UNION ALL SELECT 'Social media and ads management',      'revenue',       'in',  '4220'
  UNION ALL SELECT 'Design services',                      'revenue',       'in',  '4230'
  UNION ALL SELECT 'Exchange gain',                        'financial',     'in',  '4310'
  UNION ALL SELECT 'Bank profit',                          'financial',     'in',  '4320'
  UNION ALL SELECT 'Investor funds received',              'balance_sheet', 'in',  '2210'
  UNION ALL SELECT 'Client advance received',              'balance_sheet', 'in',  '2140'
  UNION ALL SELECT 'Rebillable spend recovered',           'balance_sheet', 'in',  '1123'

  UNION ALL SELECT 'Outsourcing and subcontractors',       'cgs',           'out', '5100'
  UNION ALL SELECT 'Client advertising spend, absorbed',   'cgs',           'out', '5200'
  UNION ALL SELECT 'Project software and tools',           'cgs',           'out', '5300'
  UNION ALL SELECT 'Platform fees',                        'cgs',           'out', '5400'
  UNION ALL SELECT 'Partner profit share',                 'cgs',           'out', '5500'
  UNION ALL SELECT 'Project travel',                       'cgs',           'out', '5600'
  UNION ALL SELECT 'Salaries and wages',                   'admin',         'out', '6100'
  UNION ALL SELECT 'Staff welfare',                        'admin',         'out', '6110'
  UNION ALL SELECT 'Rent and utilities',                   'admin',         'out', '6200'
  UNION ALL SELECT 'Telecommunication and internet',       'admin',         'out', '6300'
  UNION ALL SELECT 'Software subscriptions',               'admin',         'out', '6400'
  UNION ALL SELECT 'Hosting and domains',                  'admin',         'out', '6410'
  UNION ALL SELECT 'Travelling and conveyance',            'admin',         'out', '6500'
  UNION ALL SELECT 'Office supplies, printing and stationery', 'admin',     'out', '6600'
  UNION ALL SELECT 'Repairs and maintenance',              'admin',         'out', '6700'
  UNION ALL SELECT 'Legal, registration and professional fees', 'admin',    'out', '6800'
  UNION ALL SELECT 'Entertainment',                        'admin',         'out', '6900'
  UNION ALL SELECT 'Own advertising',                      'selling',       'out', '7100'
  UNION ALL SELECT 'Business development',                 'selling',       'out', '7200'
  UNION ALL SELECT 'Bank charges and FED',                 'financial',     'out', '8100'
  UNION ALL SELECT 'Forex and card fees',                  'financial',     'out', '8200'
  UNION ALL SELECT 'Exchange loss',                        'financial',     'out', '8300'
  UNION ALL SELECT 'Final tax, Section 154A',              'taxation',      'out', '9100'
  UNION ALL SELECT 'Income tax paid',                      'taxation',      'out', '9200'
  UNION ALL SELECT 'Rebillable client spend',              'balance_sheet', 'out', '1123'
  UNION ALL SELECT 'Equipment purchase',                   'balance_sheet', 'out', '1211'
  UNION ALL SELECT 'Advance to employee',                  'balance_sheet', 'out', '1131'
  UNION ALL SELECT 'Prepaid expense',                      'balance_sheet', 'out', '1133'
  UNION ALL SELECT 'Loan repayment to director',           'balance_sheet', 'out', '2210'
  UNION ALL SELECT 'Reimbursement to a person',            'balance_sheet', 'out', '2114'
) AS seed
JOIN chart_of_accounts coa ON coa.code = seed.code;

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

INSERT INTO settings (setting_key, value, value_type, description) VALUES
  ('base_currency',                'PKR',        'string', 'Books are kept in this currency'),
  ('fiscal_year_start_month',      '7',          'int',    'July to June, matching the Pakistan tax year'),
  ('payroll_visible_to_all',       'true',       'bool',   'Permissive now, can be restricted later'),
  ('next_invoice_number',          '5026',       'int',    'Reference only. Allocation comes from the sequences table'),
  ('receipt_required_above',       '500000',     'int',    'Paisa. 5,000 PKR'),
  ('large_cash_warning_above',     '5000000',    'int',    'Paisa. 50,000 PKR'),
  ('fx_deviation_warning_percent', '5',          'int',    'Warn if a rate is this far from the last one used'),
  ('pass_through_max_days',        '14',         'int',    'Flag money sitting in a personal account longer than this'),
  ('pseb_registered',              'true',       'bool',   'Drives the Section 154A suggestion'),
  ('pra_registered',               'false',      'bool',   'Not registered with the Punjab Revenue Authority'),
  ('petty_cash_imprest',           '0',          'int',    'Paisa. Target float, set by the admin'),
  ('books_live_from',              '2026-07-01', 'date',   'First date of live entry. Earlier dates are historical'),
  ('history_merged',               'false',      'bool',   'True once history reconciles and the opening entry is reversed'),
  ('atl_status',                   'active',     'string', 'Winibex own status. Used only when tax is deducted from Winibex');

-- ---------------------------------------------------------------------------
-- Sequences
-- ---------------------------------------------------------------------------

INSERT INTO sequences (name, prefix, next_value) VALUES
  ('journal',   'JV-',  1),
  ('invoice',   'INV-', 5026),
  ('quotation', 'QT-',  1),
  ('receipt',   'RC-',  1),
  ('voucher',   'PV-',  1);

-- ---------------------------------------------------------------------------

INSERT INTO schema_migrations (filename)
VALUES ('002_seed_reference.sql')
ON DUPLICATE KEY UPDATE filename = filename;
