--
-- PostgreSQL database dump
--

\restrict xQ9lewUYKxH7tUdXZksjZkCybDJMbmrdZSKry4nWngcyq0IDmWazVkclUwkfx8D

-- Dumped from database version 16.11 (Debian 16.11-1.pgdg12+1)
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS wu_transactions_worker_id_fkey;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS wu_transactions_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.wu_customers DROP CONSTRAINT IF EXISTS wu_customers_customer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.wu_customers DROP CONSTRAINT IF EXISTS wu_customers_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.wu_balances DROP CONSTRAINT IF EXISTS wu_balances_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.vault_transfer DROP CONSTRAINT IF EXISTS vault_transfer_target_vault_id_fkey;
ALTER TABLE IF EXISTS ONLY public.vault_transfer DROP CONSTRAINT IF EXISTS vault_transfer_source_vault_id_fkey;
ALTER TABLE IF EXISTS ONLY public.vault_distribution_line DROP CONSTRAINT IF EXISTS vault_distribution_line_distribution_id_fkey;
ALTER TABLE IF EXISTS ONLY public.vault_bank_transaction DROP CONSTRAINT IF EXISTS vault_bank_transaction_vault_territory_id_fkey;
ALTER TABLE IF EXISTS ONLY public.seal_tracking DROP CONSTRAINT IF EXISTS seal_tracking_sealed_by_fkey;
ALTER TABLE IF EXISTS ONLY public.seal_tracking DROP CONSTRAINT IF EXISTS seal_tracking_opened_by_fkey;
ALTER TABLE IF EXISTS ONLY public.seal_tracking DROP CONSTRAINT IF EXISTS seal_tracking_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.rate_template DROP CONSTRAINT IF EXISTS rate_template_currency_id_fkey;
ALTER TABLE IF EXISTS ONLY public.material_receipt DROP CONSTRAINT IF EXISTS material_receipt_vault_territory_id_fkey;
ALTER TABLE IF EXISTS ONLY public.material_receipt_line DROP CONSTRAINT IF EXISTS material_receipt_line_receipt_id_fkey;
ALTER TABLE IF EXISTS ONLY public.handling_fee_decade_report DROP CONSTRAINT IF EXISTS handling_fee_decade_report_branch_id_fkey;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS fkukcf8b5tny89ynpecoabw6m;
ALTER TABLE IF EXISTS ONLY public.data_import_jobs DROP CONSTRAINT IF EXISTS fktrk7hptqxjkviyw416ouh4028;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS fkt4us76p2nfv1ylsf1inean6w1;
ALTER TABLE IF EXISTS ONLY public.worker_session DROP CONSTRAINT IF EXISTS fkt3xj15g0csrpc8xexk11po2nk;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS fkstsm1iq0rvwv0ibw1ubg3o8qs;
ALTER TABLE IF EXISTS ONLY public.worker DROP CONSTRAINT IF EXISTS fksrbh75havvuhwy110qdth7dhy;
ALTER TABLE IF EXISTS ONLY public.closing_wizard DROP CONSTRAINT IF EXISTS fkrxxn6plxwad3a55e5d80mevb9;
ALTER TABLE IF EXISTS ONLY public.transfer_document DROP CONSTRAINT IF EXISTS fkrxp08x7ydql12r44qkto7d1nh;
ALTER TABLE IF EXISTS ONLY public.nav_closing DROP CONSTRAINT IF EXISTS fkrvwbn463wb0b9uh316ce6kc2e;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fkrfm0h87y2vhvj6yddnjrkm86y;
ALTER TABLE IF EXISTS ONLY public.cash_balance DROP CONSTRAINT IF EXISTS fkqtwri2qn6bx4ewv0ncae6vlgn;
ALTER TABLE IF EXISTS ONLY public.worker_competition_entry DROP CONSTRAINT IF EXISTS fkqq2c0v6lhqcn72nb4bnugwbva;
ALTER TABLE IF EXISTS ONLY public.ftp_sync_log DROP CONSTRAINT IF EXISTS fkqn6exv51j6bd5u05p5alcsdda;
ALTER TABLE IF EXISTS ONLY public.employee_address DROP CONSTRAINT IF EXISTS fkq100ul0qo7nuxdcbn7adypnyo;
ALTER TABLE IF EXISTS ONLY public.employee_bank_account DROP CONSTRAINT IF EXISTS fkpyvhoiaovnuto1b6mqxtddxbj;
ALTER TABLE IF EXISTS ONLY public.denomination DROP CONSTRAINT IF EXISTS fkps324y4axh0oqfyej8wgg6li4;
ALTER TABLE IF EXISTS ONLY public.exchange_rate DROP CONSTRAINT IF EXISTS fkpqmcfp4oyam6p9jcrodk1ha1q;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS fkpkfm0x3thig33xu1j3o9xj1ra;
ALTER TABLE IF EXISTS ONLY public.data_collection DROP CONSTRAINT IF EXISTS fkphl8n6hhjdqckccn0tin9go1a;
ALTER TABLE IF EXISTS ONLY public.mnb_report DROP CONSTRAINT IF EXISTS fkpe26hvodja36ocww2mk6ink5v;
ALTER TABLE IF EXISTS ONLY public.transaction_line DROP CONSTRAINT IF EXISTS fkpcwy5qy4l2qo2a67sdugbcxfr;
ALTER TABLE IF EXISTS ONLY public.inventory_summary DROP CONSTRAINT IF EXISTS fkp084axkmqb5gl81nwik9o411q;
ALTER TABLE IF EXISTS ONLY public.monthly_closing_summary DROP CONSTRAINT IF EXISTS fkorwnahq70jde5fkrp5902iind;
ALTER TABLE IF EXISTS ONLY public.circular DROP CONSTRAINT IF EXISTS fkoo3ank7a44phely3gmjul2bdl;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fkoanvi3lmgrfkudlxstrou88dn;
ALTER TABLE IF EXISTS ONLY public.monthly_closing_summary DROP CONSTRAINT IF EXISTS fko6t0vsfacc8xbrj1jawxgigjc;
ALTER TABLE IF EXISTS ONLY public.rate_approval DROP CONSTRAINT IF EXISTS fko0ne218phu1nli8hwc5k81as9;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS fkndx0a0f5wm06vp6sxhmxtm2by;
ALTER TABLE IF EXISTS ONLY public.transfer_document DROP CONSTRAINT IF EXISTS fkn6sbst0prwbqu8caxajirvfx8;
ALTER TABLE IF EXISTS ONLY public.collected_inventory DROP CONSTRAINT IF EXISTS fkmvscoitehu1lv9ywn50a8yxix;
ALTER TABLE IF EXISTS ONLY public.rate_approval DROP CONSTRAINT IF EXISTS fkmmfpmwtl2cggqgau3yaco3g6;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS fklmijd0ej4b4x22lddv313yn0m;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS fklioab2ehkn3s2aaxm74912x1i;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS fklcx7g8g7x4fyns9k6vesu3n9n;
ALTER TABLE IF EXISTS ONLY public.rate_approval DROP CONSTRAINT IF EXISTS fkl68l5s3gfr4srutb8l5ihncbt;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS fkl4vorqlvr601e28jg2srk53uo;
ALTER TABLE IF EXISTS ONLY public.worker_attendance DROP CONSTRAINT IF EXISTS fkkee0f907jq72xnbsn12863qr4;
ALTER TABLE IF EXISTS ONLY public.daily_session DROP CONSTRAINT IF EXISTS fkk0lxb8ib3q7saelevqsp9tnmm;
ALTER TABLE IF EXISTS ONLY public.police_request DROP CONSTRAINT IF EXISTS fkjpbetm0xo2kdko49svbo1kf7u;
ALTER TABLE IF EXISTS ONLY public.led_display DROP CONSTRAINT IF EXISTS fkiutpiq5asfr637ddn2q2xq3y;
ALTER TABLE IF EXISTS ONLY public.worker_role_permission DROP CONSTRAINT IF EXISTS fkira4lck9cbhyggc1a2y2bcp1l;
ALTER TABLE IF EXISTS ONLY public.decade_report DROP CONSTRAINT IF EXISTS fkipy26y7xy6nqjued0a2o39rgb;
ALTER TABLE IF EXISTS ONLY public.packaging_record DROP CONSTRAINT IF EXISTS fkilpommifplj9ocnk9naoksusk;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS fki65ouc7378d6wmp3p7b4e7lqr;
ALTER TABLE IF EXISTS ONLY public.vault_territory DROP CONSTRAINT IF EXISTS fkhx03h1j35cnn60f26ww7csfab;
ALTER TABLE IF EXISTS ONLY public.sync_log DROP CONSTRAINT IF EXISTS fkhob8tp24kg7q98dqhoabcluow;
ALTER TABLE IF EXISTS ONLY public.stamp_assignment DROP CONSTRAINT IF EXISTS fkhktm1gceqpa7m1hbeqgqba0yv;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS fkhkqs3baljryiedqie3pe22omi;
ALTER TABLE IF EXISTS ONLY public.transfer_document DROP CONSTRAINT IF EXISTS fkhfjvs5h7liiuhy17ujs3xrlb;
ALTER TABLE IF EXISTS ONLY public.worker_break DROP CONSTRAINT IF EXISTS fkhepwdcdkny0lwd9wfsjoc04in;
ALTER TABLE IF EXISTS ONLY public.rate_category DROP CONSTRAINT IF EXISTS fkh6h7hq94pi3hmlhk8yxw5pwde;
ALTER TABLE IF EXISTS ONLY public.exchange_rate DROP CONSTRAINT IF EXISTS fkh3b9j7ggn2lpd095tio6w58pp;
ALTER TABLE IF EXISTS ONLY public.profit_log DROP CONSTRAINT IF EXISTS fkgu22g65dmvfwf1mcdq9eb2yj9;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS fkgsxo3d1s9gomlaas8pmpsr53m;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS fkglo9kudrsanfwfg4ykt7cpd53;
ALTER TABLE IF EXISTS ONLY public.worker_role_assignment DROP CONSTRAINT IF EXISTS fkglmywousswlf58p1nlct2pcyp;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS fkghkpo8tvfb8pagu8x441j4o9x;
ALTER TABLE IF EXISTS ONLY public.daily_session DROP CONSTRAINT IF EXISTS fkgabb2kmaj5ah1tlft08hhyl50;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS fkg94fj3emfpi6vw3xxij57dyuw;
ALTER TABLE IF EXISTS ONLY public.transaction_line DROP CONSTRAINT IF EXISTS fkg1rcgpj1p3hcasn6ekoknvcoh;
ALTER TABLE IF EXISTS ONLY public.nav_closing_line DROP CONSTRAINT IF EXISTS fkfy4hfw6dlabi3pjfvvit40tkg;
ALTER TABLE IF EXISTS ONLY public.denomination DROP CONSTRAINT IF EXISTS fkfw9jhie54hhtbhuu34nplsq7w;
ALTER TABLE IF EXISTS ONLY public.collected_transaction DROP CONSTRAINT IF EXISTS fkfolu6klc955pui5yekie2n7ya;
ALTER TABLE IF EXISTS ONLY public.daily_report DROP CONSTRAINT IF EXISTS fkfdarypom6pspfnc572ss8yygl;
ALTER TABLE IF EXISTS ONLY public.role_permission DROP CONSTRAINT IF EXISTS fkf8yllw1ecvwqy3ehyxawqa1qp;
ALTER TABLE IF EXISTS ONLY public.led_display_config DROP CONSTRAINT IF EXISTS fkf5u3pjc7811hxkiako4bv0v97;
ALTER TABLE IF EXISTS ONLY public.wu_balances DROP CONSTRAINT IF EXISTS fkex1499e98q5irw30wwero27bv;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS fkegwf0hi4d3f54kxgr9sbfee9w;
ALTER TABLE IF EXISTS ONLY public.camera_access_log DROP CONSTRAINT IF EXISTS fkdn6bfchp9ljg0l49m2cv9w7xs;
ALTER TABLE IF EXISTS ONLY public.worker_role_permission DROP CONSTRAINT IF EXISTS fkdlo1rxmd31ch1f7hctyw4xcdr;
ALTER TABLE IF EXISTS ONLY public.shipment_request_item DROP CONSTRAINT IF EXISTS fkdl83eskxp2mpft9h46bxintmf;
ALTER TABLE IF EXISTS ONLY public.archived_transactions DROP CONSTRAINT IF EXISTS fkdkj2way11eha5bfx4684xnx07;
ALTER TABLE IF EXISTS ONLY public.daily_balance DROP CONSTRAINT IF EXISTS fkcvva0wlk4j7dlm8hfslvt0jlw;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fkcmsfp7a7g32igqd1qvg4h00ay;
ALTER TABLE IF EXISTS ONLY public.branch_group_branches DROP CONSTRAINT IF EXISTS fkcfh626bdyey86bdb529ssn8j;
ALTER TABLE IF EXISTS ONLY public.customer DROP CONSTRAINT IF EXISTS fkcc6lvs1hfb70cc5rjbyq0m8is;
ALTER TABLE IF EXISTS ONLY public.denomination DROP CONSTRAINT IF EXISTS fkc7toet3vkhgxt05gch58mcs8o;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS fkc1oossj143dlws8xw0aqbkt1a;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS fkc121s316jwayhyhberonjbt4h;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup_branch DROP CONSTRAINT IF EXISTS fkbk0fawh4jpvxjx8iseyt25mec;
ALTER TABLE IF EXISTS ONLY public.cash_balance DROP CONSTRAINT IF EXISTS fkbhofh25twlb9k04sc4bv8gq0l;
ALTER TABLE IF EXISTS ONLY public.handling_fee_bracket DROP CONSTRAINT IF EXISTS fkaxjm5sigdsi86ueu4pebrnphv;
ALTER TABLE IF EXISTS ONLY public.inventory_summary DROP CONSTRAINT IF EXISTS fkante0g9ydcw0o0oct9fdx6qwt;
ALTER TABLE IF EXISTS ONLY public.role_permission DROP CONSTRAINT IF EXISTS fka6jx8n8xkesmjmv6jqug6bg68;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fka5jkev2eso3j7bg6ppxj89nwl;
ALTER TABLE IF EXISTS ONLY public.worker_session DROP CONSTRAINT IF EXISTS fka4pxx718jnwqwiyc5rbyqxect;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS fka3irmae6dx30cj3g27pywkimh;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS fka091bj9n9g8lxc6xcs7crff33;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS fk_wu_transactions_reversed;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup DROP CONSTRAINT IF EXISTS fk_rate_workgroup_company;
ALTER TABLE IF EXISTS ONLY public.rate_template DROP CONSTRAINT IF EXISTS fk_rate_template_company;
ALTER TABLE IF EXISTS ONLY public.rate_publication DROP CONSTRAINT IF EXISTS fk_rate_publication_workgroup;
ALTER TABLE IF EXISTS ONLY public.rate_publication DROP CONSTRAINT IF EXISTS fk_rate_publication_company;
ALTER TABLE IF EXISTS ONLY public.rate_discount DROP CONSTRAINT IF EXISTS fk_rate_discount_company;
ALTER TABLE IF EXISTS ONLY public.darius_daily_report DROP CONSTRAINT IF EXISTS fk_darius_report_company;
ALTER TABLE IF EXISTS ONLY public.darius_report_line DROP CONSTRAINT IF EXISTS fk_darius_line_report;
ALTER TABLE IF EXISTS ONLY public.darius_report_line DROP CONSTRAINT IF EXISTS fk_darius_line_branch;
ALTER TABLE IF EXISTS ONLY public.competitor_rates DROP CONSTRAINT IF EXISTS fk_comp_rate_currency;
ALTER TABLE IF EXISTS ONLY public.competitor_rates DROP CONSTRAINT IF EXISTS fk_comp_rate_competitor;
ALTER TABLE IF EXISTS ONLY public.chain_of_custody_record DROP CONSTRAINT IF EXISTS fk_coc_export;
ALTER TABLE IF EXISTS ONLY public.chain_of_custody_record DROP CONSTRAINT IF EXISTS fk_coc_branch;
ALTER TABLE IF EXISTS ONLY public.camera_segment_hash DROP CONSTRAINT IF EXISTS fk_camera_hash_recording;
ALTER TABLE IF EXISTS ONLY public.camera_segment_hash DROP CONSTRAINT IF EXISTS fk_camera_hash_branch;
ALTER TABLE IF EXISTS ONLY public.camera_export_request DROP CONSTRAINT IF EXISTS fk_camera_export_branch;
ALTER TABLE IF EXISTS ONLY public.cash_balance DROP CONSTRAINT IF EXISTS fk9v8i1tvg6y14h2bv8uo5ouea3;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS fk9kj1sqk9j3dqbgs7trb3emrwj;
ALTER TABLE IF EXISTS ONLY public.trade DROP CONSTRAINT IF EXISTS fk98pk4telc0fdeqwr5bax9x3pb;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS fk97jwc2s2eni3nvuqujp6qk87o;
ALTER TABLE IF EXISTS ONLY public.email_cache DROP CONSTRAINT IF EXISTS fk90ige8ir5gkkvyqpfhsrs0wxo;
ALTER TABLE IF EXISTS ONLY public.currency_stock DROP CONSTRAINT IF EXISTS fk8yv5dtyir00vru3mr3w4l9nvc;
ALTER TABLE IF EXISTS ONLY public.cash_register_event DROP CONSTRAINT IF EXISTS fk8nbub0ocjb23bmgdf2goqqxe7;
ALTER TABLE IF EXISTS ONLY public.mnb_report_line DROP CONSTRAINT IF EXISTS fk7ygfjj1dows9xq12arvkofsrr;
ALTER TABLE IF EXISTS ONLY public.inventory_regeneration DROP CONSTRAINT IF EXISTS fk7wrx2sboxdwxf7eq1iwlhqpk0;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS fk7v1qsurejgkn41dr03anjgb1x;
ALTER TABLE IF EXISTS ONLY public.daily_report DROP CONSTRAINT IF EXISTS fk7om7n2xkwp4rpre6iduwwxnki;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS fk7nhs5640vcyrq7u39odc0jsvd;
ALTER TABLE IF EXISTS ONLY public.wu_customers DROP CONSTRAINT IF EXISTS fk6tb66h65p2xmuihasvriojdo3;
ALTER TABLE IF EXISTS ONLY public.daily_session DROP CONSTRAINT IF EXISTS fk6rqtg3k7a2puktlc5w72k4iuy;
ALTER TABLE IF EXISTS ONLY public.closing_wizard_step DROP CONSTRAINT IF EXISTS fk6bhep8r9t3ro6ufpspd6lpr91;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS fk67x0jrs2q3l7neymsrgys54ip;
ALTER TABLE IF EXISTS ONLY public.closing_wizard DROP CONSTRAINT IF EXISTS fk66tpw0fvureaoucvpo9dvhqx6;
ALTER TABLE IF EXISTS ONLY public.denomination_balance DROP CONSTRAINT IF EXISTS fk66c0yuujhg6drbu3paqwsgvg2;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS fk663p7ti35m6atop4eipkfb0t;
ALTER TABLE IF EXISTS ONLY public.employee DROP CONSTRAINT IF EXISTS fk5v50ed2bjh60n1gc7ifuxmgf4;
ALTER TABLE IF EXISTS ONLY public.nav_closing DROP CONSTRAINT IF EXISTS fk5hcd7uoailyihpw9r0ky1pp6k;
ALTER TABLE IF EXISTS ONLY public.worker_session DROP CONSTRAINT IF EXISTS fk5hbcx1hhjndf9ct7qc6215vem;
ALTER TABLE IF EXISTS ONLY public.exchange_rate DROP CONSTRAINT IF EXISTS fk55yjrct1osthhit3wsdy63omr;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fk51sk1dyhp96yvr0s7mplyvuct;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup_branch DROP CONSTRAINT IF EXISTS fk4k60flrhf7ja23rpmuha58iu2;
ALTER TABLE IF EXISTS ONLY public.closing_wizard DROP CONSTRAINT IF EXISTS fk4it5vhuckhnq7qgngty84t58r;
ALTER TABLE IF EXISTS ONLY public.aml_report DROP CONSTRAINT IF EXISTS fk4hv0o4di9hf8td6mx6t9nvgpx;
ALTER TABLE IF EXISTS ONLY public.trade DROP CONSTRAINT IF EXISTS fk47gfq4rln4hbtpkdwuswp3mo0;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS fk41v6ueo0hiran65w8y1cta2c2;
ALTER TABLE IF EXISTS ONLY public.daily_session DROP CONSTRAINT IF EXISTS fk3yq5vk01cjybysh133lblt8gr;
ALTER TABLE IF EXISTS ONLY public.employee DROP CONSTRAINT IF EXISTS fk3ygtr6ktpgwioh03vhtj6kxaw;
ALTER TABLE IF EXISTS ONLY public.worker_role_assignment DROP CONSTRAINT IF EXISTS fk3lmfkc5no6ne8cgsrnseu3v12;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS fk35regpv835ry265jyut8ilux7;
ALTER TABLE IF EXISTS ONLY public.transfer_document DROP CONSTRAINT IF EXISTS fk35nqywhjv3q9q40ncp5erjymx;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS fk30d8yogioe8fubwsaf1f73x19;
ALTER TABLE IF EXISTS ONLY public.camera_transaction_link DROP CONSTRAINT IF EXISTS fk2y0xrcttwe5yhqh9s6h5af0r0;
ALTER TABLE IF EXISTS ONLY public.initial_fee_config DROP CONSTRAINT IF EXISTS fk2tvodc8n46w9k7fx1loo97ge3;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS fk2l8us96rhbpbdbntqhl14dew4;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS fk1wksaeptng6kdfw5ro7ierplg;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS fk1t6qrqj815ftox3wbme7dcb2t;
ALTER TABLE IF EXISTS ONLY public.inventory_regeneration DROP CONSTRAINT IF EXISTS fk1op44pb8qwuvj774sqce112lv;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS fk1i7ggk2voycuivq9f0mkruejx;
ALTER TABLE IF EXISTS ONLY public.aml_report DROP CONSTRAINT IF EXISTS fk1dor9bgxil7bs8dwxdsrwklnw;
ALTER TABLE IF EXISTS ONLY public.worker DROP CONSTRAINT IF EXISTS fk1856lfikvij3xma8ourmkw8d;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS fk14f9k065wqeubl6tl0gdumcp5;
ALTER TABLE IF EXISTS ONLY public.decade_report_line DROP CONSTRAINT IF EXISTS decade_report_line_decade_report_id_fkey;
ALTER TABLE IF EXISTS ONLY public.daily_checklist_item DROP CONSTRAINT IF EXISTS daily_checklist_item_checklist_id_fkey;
ALTER TABLE IF EXISTS ONLY public.daily_checklist DROP CONSTRAINT IF EXISTS daily_checklist_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.daily_checklist DROP CONSTRAINT IF EXISTS daily_checklist_branch_id_fkey;
ALTER TABLE IF EXISTS ONLY public.circular_acknowledgment DROP CONSTRAINT IF EXISTS circular_acknowledgment_circular_id_fkey;
DROP INDEX IF EXISTS public.uq_wu_customers_name_document;
DROP INDEX IF EXISTS public.uq_wu_customer_company_name_idnum;
DROP INDEX IF EXISTS public.uq_seal_tracking_company_seal;
DROP INDEX IF EXISTS public.uk_workstation_code;
DROP INDEX IF EXISTS public.uk_worker_email;
DROP INDEX IF EXISTS public.uk_system_parameter_key;
DROP INDEX IF EXISTS public.uk_shipment_request_number;
DROP INDEX IF EXISTS public.uk_receipt_number;
DROP INDEX IF EXISTS public.uk_pos_terminal_terminal_id;
DROP INDEX IF EXISTS public.uk_organization_code;
DROP INDEX IF EXISTS public.uk_handover_sheet_number;
DROP INDEX IF EXISTS public.uk_fee_type_code;
DROP INDEX IF EXISTS public.uk_fee_discount_code;
DROP INDEX IF EXISTS public.uk_currency_group_code;
DROP INDEX IF EXISTS public.uk_branch_group_code;
DROP INDEX IF EXISTS public.idx_wu_transactions_mtcn;
DROP INDEX IF EXISTS public.idx_wu_transactions_date;
DROP INDEX IF EXISTS public.idx_wu_transactions_company;
DROP INDEX IF EXISTS public.idx_wu_transactions_branch;
DROP INDEX IF EXISTS public.idx_wu_balance_branch_company;
DROP INDEX IF EXISTS public.idx_vault_transfer_status;
DROP INDEX IF EXISTS public.idx_vault_transfer_number;
DROP INDEX IF EXISTS public.idx_vault_transfer_date;
DROP INDEX IF EXISTS public.idx_vault_transfer_company;
DROP INDEX IF EXISTS public.idx_vault_distribution_status;
DROP INDEX IF EXISTS public.idx_vault_distribution_company;
DROP INDEX IF EXISTS public.idx_vault_dist_line_dist;
DROP INDEX IF EXISTS public.idx_vault_collection_status;
DROP INDEX IF EXISTS public.idx_vault_collection_company;
DROP INDEX IF EXISTS public.idx_vault_collection_branch;
DROP INDEX IF EXISTS public.idx_vault_bank_tx_type;
DROP INDEX IF EXISTS public.idx_vault_bank_tx_status;
DROP INDEX IF EXISTS public.idx_vault_bank_tx_date;
DROP INDEX IF EXISTS public.idx_vault_bank_tx_company;
DROP INDEX IF EXISTS public.idx_txline_transaction;
DROP INDEX IF EXISTS public.idx_txline_currency;
DROP INDEX IF EXISTS public.idx_translation_module;
DROP INDEX IF EXISTS public.idx_transfer_doc_status;
DROP INDEX IF EXISTS public.idx_transfer_doc_courier;
DROP INDEX IF EXISTS public.idx_transfer_doc_company;
DROP INDEX IF EXISTS public.idx_transaction_worker;
DROP INDEX IF EXISTS public.idx_transaction_receipt;
DROP INDEX IF EXISTS public.idx_transaction_original_id;
DROP INDEX IF EXISTS public.idx_transaction_linked_receipt;
DROP INDEX IF EXISTS public.idx_transaction_date;
DROP INDEX IF EXISTS public.idx_transaction_company_date;
DROP INDEX IF EXISTS public.idx_transaction_company_customer_date;
DROP INDEX IF EXISTS public.idx_transaction_company;
DROP INDEX IF EXISTS public.idx_transaction_branch_date_status;
DROP INDEX IF EXISTS public.idx_transaction_branch;
DROP INDEX IF EXISTS public.idx_token_blacklist_token_id;
DROP INDEX IF EXISTS public.idx_token_blacklist_expires_at;
DROP INDEX IF EXISTS public.idx_sync_outbox_status_next_retry;
DROP INDEX IF EXISTS public.idx_sync_outbox_created_at;
DROP INDEX IF EXISTS public.idx_sync_inbox_status;
DROP INDEX IF EXISTS public.idx_sync_inbox_received_at;
DROP INDEX IF EXISTS public.idx_storno_approval_worker;
DROP INDEX IF EXISTS public.idx_storno_approval_transaction;
DROP INDEX IF EXISTS public.idx_storno_approval_branch;
DROP INDEX IF EXISTS public.idx_stock_correction_entity;
DROP INDEX IF EXISTS public.idx_stock_correction_company;
DROP INDEX IF EXISTS public.idx_shipment_request_status;
DROP INDEX IF EXISTS public.idx_seal_tracking_transfer;
DROP INDEX IF EXISTS public.idx_seal_tracking_company_status;
DROP INDEX IF EXISTS public.idx_seal_tracking_company;
DROP INDEX IF EXISTS public.idx_seal_branch;
DROP INDEX IF EXISTS public.idx_screening_log_worker;
DROP INDEX IF EXISTS public.idx_screening_log_screened_name;
DROP INDEX IF EXISTS public.idx_screening_log_result;
DROP INDEX IF EXISTS public.idx_screening_log_created;
DROP INDEX IF EXISTS public.idx_scanned_document_type;
DROP INDEX IF EXISTS public.idx_scanned_document_transaction;
DROP INDEX IF EXISTS public.idx_scanned_document_customer;
DROP INDEX IF EXISTS public.idx_sanction_list_type;
DROP INDEX IF EXISTS public.idx_sanction_full_name;
DROP INDEX IF EXISTS public.idx_sanction_document_number;
DROP INDEX IF EXISTS public.idx_sanction_active;
DROP INDEX IF EXISTS public.idx_rounding_rule_currency;
DROP INDEX IF EXISTS public.idx_reservation_status;
DROP INDEX IF EXISTS public.idx_reservation_receipt;
DROP INDEX IF EXISTS public.idx_reservation_expires;
DROP INDEX IF EXISTS public.idx_reservation_customer;
DROP INDEX IF EXISTS public.idx_reservation_company;
DROP INDEX IF EXISTS public.idx_reservation_branch;
DROP INDEX IF EXISTS public.idx_receipt_seq_branch;
DROP INDEX IF EXISTS public.idx_rate_workgroup_company;
DROP INDEX IF EXISTS public.idx_rate_template_wg_status;
DROP INDEX IF EXISTS public.idx_rate_template_currency;
DROP INDEX IF EXISTS public.idx_rate_template_company;
DROP INDEX IF EXISTS public.idx_rate_publication_wg;
DROP INDEX IF EXISTS public.idx_rate_publication_company;
DROP INDEX IF EXISTS public.idx_rate_history_dates;
DROP INDEX IF EXISTS public.idx_rate_history_currency;
DROP INDEX IF EXISTS public.idx_rate_history_company;
DROP INDEX IF EXISTS public.idx_rate_history_branch;
DROP INDEX IF EXISTS public.idx_rate_discount_company_id;
DROP INDEX IF EXISTS public.idx_rate_category_currency;
DROP INDEX IF EXISTS public.idx_rate_category_branch;
DROP INDEX IF EXISTS public.idx_rate_approval_status;
DROP INDEX IF EXISTS public.idx_rate_approval_branch;
DROP INDEX IF EXISTS public.idx_profit_log_company;
DROP INDEX IF EXISTS public.idx_profit_log_branch;
DROP INDEX IF EXISTS public.idx_police_request_status;
DROP INDEX IF EXISTS public.idx_police_request_date;
DROP INDEX IF EXISTS public.idx_packaging_date;
DROP INDEX IF EXISTS public.idx_packaging_branch;
DROP INDEX IF EXISTS public.idx_notification_user_read;
DROP INDEX IF EXISTS public.idx_notification_user_created;
DROP INDEX IF EXISTS public.idx_notification_entity_type_id_ntype;
DROP INDEX IF EXISTS public.idx_nav_line_currency;
DROP INDEX IF EXISTS public.idx_nav_line_closing;
DROP INDEX IF EXISTS public.idx_nav_closing_type_date;
DROP INDEX IF EXISTS public.idx_nav_closing_status;
DROP INDEX IF EXISTS public.idx_nav_closing_branch_date;
DROP INDEX IF EXISTS public.idx_monthly_closing_yearmonth;
DROP INDEX IF EXISTS public.idx_monthly_closing_period;
DROP INDEX IF EXISTS public.idx_monthly_closing_company;
DROP INDEX IF EXISTS public.idx_monthly_closing_branch;
DROP INDEX IF EXISTS public.idx_mnb_report_type_date;
DROP INDEX IF EXISTS public.idx_mnb_report_status;
DROP INDEX IF EXISTS public.idx_mnb_report_branch_date;
DROP INDEX IF EXISTS public.idx_mnb_rate_date;
DROP INDEX IF EXISTS public.idx_mnb_rate_currency;
DROP INDEX IF EXISTS public.idx_mnb_line_report;
DROP INDEX IF EXISTS public.idx_mnb_line_currency;
DROP INDEX IF EXISTS public.idx_material_receipt_type;
DROP INDEX IF EXISTS public.idx_material_receipt_number;
DROP INDEX IF EXISTS public.idx_material_receipt_line_receipt;
DROP INDEX IF EXISTS public.idx_material_receipt_company;
DROP INDEX IF EXISTS public.idx_led_display_config_branch;
DROP INDEX IF EXISTS public.idx_led_display_branch_unique;
DROP INDEX IF EXISTS public.idx_led_display_branch;
DROP INDEX IF EXISTS public.idx_inv_sum_date;
DROP INDEX IF EXISTS public.idx_inv_sum_currency;
DROP INDEX IF EXISTS public.idx_inv_sum_branch;
DROP INDEX IF EXISTS public.idx_inv_regen_branch;
DROP INDEX IF EXISTS public.idx_inv_mov_type;
DROP INDEX IF EXISTS public.idx_inv_mov_to_branch;
DROP INDEX IF EXISTS public.idx_inv_mov_status;
DROP INDEX IF EXISTS public.idx_inv_mov_from_branch;
DROP INDEX IF EXISTS public.idx_inv_mov_date;
DROP INDEX IF EXISTS public.idx_inv_mov_currency;
DROP INDEX IF EXISTS public.idx_initfee_company;
DROP INDEX IF EXISTS public.idx_hf_transaction_tx;
DROP INDEX IF EXISTS public.idx_hf_decade_year;
DROP INDEX IF EXISTS public.idx_hf_decade_branch;
DROP INDEX IF EXISTS public.idx_ftp_sync_log_status;
DROP INDEX IF EXISTS public.idx_ftp_sync_log_started;
DROP INDEX IF EXISTS public.idx_ftp_sync_log_branch;
DROP INDEX IF EXISTS public.idx_fee_bracket_company;
DROP INDEX IF EXISTS public.idx_exchange_rate_date;
DROP INDEX IF EXISTS public.idx_exchange_rate_currency;
DROP INDEX IF EXISTS public.idx_exchange_rate_company;
DROP INDEX IF EXISTS public.idx_evening_sync_branch_date;
DROP INDEX IF EXISTS public.idx_document_company_id;
DROP INDEX IF EXISTS public.idx_denomination_currency;
DROP INDEX IF EXISTS public.idx_denomination_branch;
DROP INDEX IF EXISTS public.idx_denom_count_session;
DROP INDEX IF EXISTS public.idx_denom_count_category;
DROP INDEX IF EXISTS public.idx_denom_count_branch;
DROP INDEX IF EXISTS public.idx_denom_balance_desk;
DROP INDEX IF EXISTS public.idx_denom_balance_denomination;
DROP INDEX IF EXISTS public.idx_denom_balance_category;
DROP INDEX IF EXISTS public.idx_decade_report_year;
DROP INDEX IF EXISTS public.idx_decade_report_branch;
DROP INDEX IF EXISTS public.idx_decade_line_report;
DROP INDEX IF EXISTS public.idx_dc_type;
DROP INDEX IF EXISTS public.idx_dc_status;
DROP INDEX IF EXISTS public.idx_dc_branch_date;
DROP INDEX IF EXISTS public.idx_data_import_jobs_type;
DROP INDEX IF EXISTS public.idx_data_import_jobs_status;
DROP INDEX IF EXISTS public.idx_data_import_jobs_branch;
DROP INDEX IF EXISTS public.idx_darius_report_status;
DROP INDEX IF EXISTS public.idx_darius_report_date;
DROP INDEX IF EXISTS public.idx_darius_report_company;
DROP INDEX IF EXISTS public.idx_darius_line_report;
DROP INDEX IF EXISTS public.idx_darius_line_branch;
DROP INDEX IF EXISTS public.idx_daily_session_date;
DROP INDEX IF EXISTS public.idx_daily_session_branch;
DROP INDEX IF EXISTS public.idx_daily_report_date;
DROP INDEX IF EXISTS public.idx_daily_report_branch;
DROP INDEX IF EXISTS public.idx_daily_checklist_item_checklist;
DROP INDEX IF EXISTS public.idx_daily_checklist_company;
DROP INDEX IF EXISTS public.idx_daily_checklist_branch_date;
DROP INDEX IF EXISTS public.idx_daily_balance_date;
DROP INDEX IF EXISTS public.idx_daily_balance_currency;
DROP INDEX IF EXISTS public.idx_daily_balance_company;
DROP INDEX IF EXISTS public.idx_daily_balance_branch_date;
DROP INDEX IF EXISTS public.idx_customer_document;
DROP INDEX IF EXISTS public.idx_customer_company;
DROP INDEX IF EXISTS public.idx_currency_stock_entity;
DROP INDEX IF EXISTS public.idx_ct_original;
DROP INDEX IF EXISTS public.idx_ct_currency;
DROP INDEX IF EXISTS public.idx_ct_collection;
DROP INDEX IF EXISTS public.idx_competitor_rate_comp;
DROP INDEX IF EXISTS public.idx_competition_status;
DROP INDEX IF EXISTS public.idx_comp_entry_worker;
DROP INDEX IF EXISTS public.idx_comp_entry_competition;
DROP INDEX IF EXISTS public.idx_comm_rule_tier;
DROP INDEX IF EXISTS public.idx_comm_rule_company;
DROP INDEX IF EXISTS public.idx_comm_calc_status;
DROP INDEX IF EXISTS public.idx_comm_calc_period;
DROP INDEX IF EXISTS public.idx_comm_calc_branch;
DROP INDEX IF EXISTS public.idx_coc_timestamp;
DROP INDEX IF EXISTS public.idx_coc_export;
DROP INDEX IF EXISTS public.idx_coc_branch;
DROP INDEX IF EXISTS public.idx_closing_wizard_step_wizard;
DROP INDEX IF EXISTS public.idx_closing_wizard_status;
DROP INDEX IF EXISTS public.idx_closing_wizard_branch;
DROP INDEX IF EXISTS public.idx_circular_urgent;
DROP INDEX IF EXISTS public.idx_circular_created_by;
DROP INDEX IF EXISTS public.idx_circular_company;
DROP INDEX IF EXISTS public.idx_circular_category;
DROP INDEX IF EXISTS public.idx_circular_archived;
DROP INDEX IF EXISTS public.idx_circ_ack_worker;
DROP INDEX IF EXISTS public.idx_circ_ack_unacked;
DROP INDEX IF EXISTS public.idx_circ_ack_circular;
DROP INDEX IF EXISTS public.idx_ci_currency;
DROP INDEX IF EXISTS public.idx_ci_collection;
DROP INDEX IF EXISTS public.idx_cash_register_event_type;
DROP INDEX IF EXISTS public.idx_cash_register_event_timestamp;
DROP INDEX IF EXISTS public.idx_cash_register_event_branch;
DROP INDEX IF EXISTS public.idx_cash_desk_break_desk;
DROP INDEX IF EXISTS public.idx_cash_desk_break_active;
DROP INDEX IF EXISTS public.idx_cash_balance_currency;
DROP INDEX IF EXISTS public.idx_cash_balance_branch;
DROP INDEX IF EXISTS public.idx_camera_tx_link_tx;
DROP INDEX IF EXISTS public.idx_camera_tx_link_receipt;
DROP INDEX IF EXISTS public.idx_camera_recording_expires;
DROP INDEX IF EXISTS public.idx_camera_recording_branch_date;
DROP INDEX IF EXISTS public.idx_camera_hash_sequence;
DROP INDEX IF EXISTS public.idx_camera_hash_recording;
DROP INDEX IF EXISTS public.idx_camera_hash_branch_camera;
DROP INDEX IF EXISTS public.idx_camera_export_status;
DROP INDEX IF EXISTS public.idx_camera_export_created;
DROP INDEX IF EXISTS public.idx_camera_export_branch;
DROP INDEX IF EXISTS public.idx_branch_region_code;
DROP INDEX IF EXISTS public.idx_bgg_branch_group;
DROP INDEX IF EXISTS public.idx_auth_rep_customer;
DROP INDEX IF EXISTS public.idx_auth_log_representative;
DROP INDEX IF EXISTS public.idx_audit_log_entity_type;
DROP INDEX IF EXISTS public.idx_audit_log_created_at;
DROP INDEX IF EXISTS public.idx_audit_log_company_id;
DROP INDEX IF EXISTS public.idx_audit_log_action;
DROP INDEX IF EXISTS public.idx_archived_original;
DROP INDEX IF EXISTS public.idx_archived_month;
DROP INDEX IF EXISTS public.idx_archived_date;
DROP INDEX IF EXISTS public.idx_archived_company;
DROP INDEX IF EXISTS public.idx_archived_branch;
DROP INDEX IF EXISTS public.idx_amt_closing;
DROP INDEX IF EXISTS public.idx_amt_branch_ym;
DROP INDEX IF EXISTS public.idx_aml_report_type;
DROP INDEX IF EXISTS public.idx_aml_report_status;
DROP INDEX IF EXISTS public.idx_aml_report_customer;
DROP INDEX IF EXISTS public.idx_aml_report_created;
DROP INDEX IF EXISTS public.idx_aml_report_company;
DROP INDEX IF EXISTS public.flyway_schema_history_s_idx;
DROP INDEX IF EXISTS public.error_logs_severity_idx;
DROP INDEX IF EXISTS public.error_logs_resolved_idx;
DROP INDEX IF EXISTS public.error_logs_fingerprint_idx;
DROP INDEX IF EXISTS public.error_logs_created_at_idx;
ALTER TABLE IF EXISTS ONLY public.wu_transactions DROP CONSTRAINT IF EXISTS wu_transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.wu_customers DROP CONSTRAINT IF EXISTS wu_customers_pkey;
ALTER TABLE IF EXISTS ONLY public.wu_balances DROP CONSTRAINT IF EXISTS wu_balances_pkey;
ALTER TABLE IF EXISTS ONLY public.workstation DROP CONSTRAINT IF EXISTS workstation_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_session DROP CONSTRAINT IF EXISTS worker_session_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_role_permission DROP CONSTRAINT IF EXISTS worker_role_permission_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_role_def DROP CONSTRAINT IF EXISTS worker_role_def_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_role_assignment DROP CONSTRAINT IF EXISTS worker_role_assignment_pkey;
ALTER TABLE IF EXISTS ONLY public.worker DROP CONSTRAINT IF EXISTS worker_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_competition DROP CONSTRAINT IF EXISTS worker_competition_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_competition_entry DROP CONSTRAINT IF EXISTS worker_competition_entry_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_commission DROP CONSTRAINT IF EXISTS worker_commission_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_break DROP CONSTRAINT IF EXISTS worker_break_pkey;
ALTER TABLE IF EXISTS ONLY public.worker_attendance DROP CONSTRAINT IF EXISTS worker_attendance_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_transfer DROP CONSTRAINT IF EXISTS vault_transfer_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_territory DROP CONSTRAINT IF EXISTS vault_territory_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_distribution DROP CONSTRAINT IF EXISTS vault_distribution_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_distribution_line DROP CONSTRAINT IF EXISTS vault_distribution_line_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_collection DROP CONSTRAINT IF EXISTS vault_collection_pkey;
ALTER TABLE IF EXISTS ONLY public.vault_bank_transaction DROP CONSTRAINT IF EXISTS vault_bank_transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.wu_balances DROP CONSTRAINT IF EXISTS uq_wu_balances_branch_company;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup DROP CONSTRAINT IF EXISTS uq_rate_workgroup_company_code;
ALTER TABLE IF EXISTS ONLY public.data_collection DROP CONSTRAINT IF EXISTS uq_dc_branch_date_type;
ALTER TABLE IF EXISTS ONLY public.daily_checklist DROP CONSTRAINT IF EXISTS uq_daily_checklist_branch_date;
ALTER TABLE IF EXISTS ONLY public.daily_balance DROP CONSTRAINT IF EXISTS uq_daily_balance_branch_date_currency;
ALTER TABLE IF EXISTS ONLY public.daily_checklist_item DROP CONSTRAINT IF EXISTS uq_checklist_item_number;
ALTER TABLE IF EXISTS ONLY public.mnb_exchange_rate_cache DROP CONSTRAINT IF EXISTS ukukodymsn5g7gg50go7yyuvba;
ALTER TABLE IF EXISTS ONLY public.currency_stock DROP CONSTRAINT IF EXISTS uks5kmxuc76mo4kjvk09k1fh495;
ALTER TABLE IF EXISTS ONLY public.monthly_closing_summary DROP CONSTRAINT IF EXISTS ukqtj8v1kuxaicloyh8uk0xha1;
ALTER TABLE IF EXISTS ONLY public.worker DROP CONSTRAINT IF EXISTS ukowmkg9ktgk2hpdqtlx47hhxxn;
ALTER TABLE IF EXISTS ONLY public.dictionary DROP CONSTRAINT IF EXISTS ukmaieooo8mjsran68glb26jleg;
ALTER TABLE IF EXISTS ONLY public.rate_discount DROP CONSTRAINT IF EXISTS ukl12w1vuhvd06gd57impmwd7fj;
ALTER TABLE IF EXISTS ONLY public.vault_territory DROP CONSTRAINT IF EXISTS ukinu4rvb14h9mdm2aten5o1no7;
ALTER TABLE IF EXISTS ONLY public.camera_config DROP CONSTRAINT IF EXISTS ukbgfnc2j3ocujko9i7i554qrh3;
ALTER TABLE IF EXISTS ONLY public.license DROP CONSTRAINT IF EXISTS uk_ynvhomt1nm4ca2yu66iv2s33;
ALTER TABLE IF EXISTS ONLY public.receipt DROP CONSTRAINT IF EXISTS uk_tbqak8g0j5h1f1bbonfylcc06;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS uk_sfe9sojfuh1x78xllwjp35iu8;
ALTER TABLE IF EXISTS ONLY public.rate_category DROP CONSTRAINT IF EXISTS uk_rate_category;
ALTER TABLE IF EXISTS ONLY public.fee_discount DROP CONSTRAINT IF EXISTS uk_r9tlvfq2gon8aci853i99v5ya;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup DROP CONSTRAINT IF EXISTS uk_pq9ftwxofiiv3dqabwwavd5wd;
ALTER TABLE IF EXISTS ONLY public.branch_group DROP CONSTRAINT IF EXISTS uk_neetakt150dcxa5td6yax09bq;
ALTER TABLE IF EXISTS ONLY public.stamp_assignment DROP CONSTRAINT IF EXISTS uk_j6xo43lijsuabnaya3osfrphq;
ALTER TABLE IF EXISTS ONLY public.inventory_summary DROP CONSTRAINT IF EXISTS uk_inv_sum_branch_currency_date;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS uk_inv_mov_ref_number;
ALTER TABLE IF EXISTS ONLY public.worker_role_def DROP CONSTRAINT IF EXISTS uk_hj5hkrqswcni832g3a4ja6f2y;
ALTER TABLE IF EXISTS ONLY public.handling_fee_decade_report DROP CONSTRAINT IF EXISTS uk_hf_decade_branch_year_decade;
ALTER TABLE IF EXISTS ONLY public.currency DROP CONSTRAINT IF EXISTS uk_h84pd2rtr12isnifnj655rkra;
ALTER TABLE IF EXISTS ONLY public.handover_sheet DROP CONSTRAINT IF EXISTS uk_gftqd2q8w5kgierxqpn6bl0rp;
ALTER TABLE IF EXISTS ONLY public.system_parameter DROP CONSTRAINT IF EXISTS uk_fklorvbynxmc618u47kqsedbw;
ALTER TABLE IF EXISTS ONLY public.rounding_rule DROP CONSTRAINT IF EXISTS uk_fj6m1rvk7lfw5sgg8igba0pxd;
ALTER TABLE IF EXISTS ONLY public.currency_group DROP CONSTRAINT IF EXISTS uk_f7bakcom01i2alrih2yque9vh;
ALTER TABLE IF EXISTS ONLY public.pos_terminal DROP CONSTRAINT IF EXISTS uk_f6qt8x339t7li5xyd1voygyl7;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS uk_f0gwphsg8g5i4rfbyeo6vvf11;
ALTER TABLE IF EXISTS ONLY public.workstation DROP CONSTRAINT IF EXISTS uk_ehpsna3rcdy3jp8t8qdf9d9sf;
ALTER TABLE IF EXISTS ONLY public.decade_report DROP CONSTRAINT IF EXISTS uk_decade_report_branch_year_decade;
ALTER TABLE IF EXISTS ONLY public.decade_report_line DROP CONSTRAINT IF EXISTS uk_decade_line_report_currency;
ALTER TABLE IF EXISTS ONLY public.darius_daily_report DROP CONSTRAINT IF EXISTS uk_darius_report_company_date;
ALTER TABLE IF EXISTS ONLY public.daily_report DROP CONSTRAINT IF EXISTS uk_daily_report_branch_date;
ALTER TABLE IF EXISTS ONLY public.worker_competition_entry DROP CONSTRAINT IF EXISTS uk_comp_entry;
ALTER TABLE IF EXISTS ONLY public.commission_calculation DROP CONSTRAINT IF EXISTS uk_comm_calc_worker_period;
ALTER TABLE IF EXISTS ONLY public.camera_segment_hash DROP CONSTRAINT IF EXISTS uk_camera_hash_sequence;
ALTER TABLE IF EXISTS ONLY public.role DROP CONSTRAINT IF EXISTS uk_c36say97xydpmgigg38qv5l2p;
ALTER TABLE IF EXISTS ONLY public.permission DROP CONSTRAINT IF EXISTS uk_a7ujv987la0i7a0o91ueevchc;
ALTER TABLE IF EXISTS ONLY public.company DROP CONSTRAINT IF EXISTS uk_8pha7u18i980jasccc4ekh7gg;
ALTER TABLE IF EXISTS ONLY public.feor_code DROP CONSTRAINT IF EXISTS uk_865l1c8tefl67bmwcpds1oncs;
ALTER TABLE IF EXISTS ONLY public.aml_threshold DROP CONSTRAINT IF EXISTS uk_74y01bto5d0cjwugaxtcnbqb5;
ALTER TABLE IF EXISTS ONLY public.branch_status DROP CONSTRAINT IF EXISTS uk_6aspr4ib0pv8vmgbu4uc875qc;
ALTER TABLE IF EXISTS ONLY public.fee_type DROP CONSTRAINT IF EXISTS uk_3gef756klr7e0e2ua32iogumj;
ALTER TABLE IF EXISTS ONLY public.error_logs DROP CONSTRAINT IF EXISTS uk_2uk20408yx23iqxjl445flo0x;
ALTER TABLE IF EXISTS ONLY public.organization DROP CONSTRAINT IF EXISTS uk_27tbqbmjb9kf4al49ojliavjt;
ALTER TABLE IF EXISTS ONLY public.email_cache DROP CONSTRAINT IF EXISTS uk83jaiuwyvfqtvwlb0qbbmclr0;
ALTER TABLE IF EXISTS ONLY public.worker_role_assignment DROP CONSTRAINT IF EXISTS uk4p0tf5sfgkqju9ea3tkbbe3we;
ALTER TABLE IF EXISTS ONLY public.denomination_balance DROP CONSTRAINT IF EXISTS uk4g8glqo7rah6ebhlltscwyvdx;
ALTER TABLE IF EXISTS ONLY public.cash_balance DROP CONSTRAINT IF EXISTS uk2vf5a63ep5394iipeqva65c7;
ALTER TABLE IF EXISTS ONLY public.translation DROP CONSTRAINT IF EXISTS translation_pkey;
ALTER TABLE IF EXISTS ONLY public.transfer DROP CONSTRAINT IF EXISTS transfer_pkey;
ALTER TABLE IF EXISTS ONLY public.transfer_document DROP CONSTRAINT IF EXISTS transfer_document_pkey;
ALTER TABLE IF EXISTS ONLY public.transaction DROP CONSTRAINT IF EXISTS transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.transaction_line DROP CONSTRAINT IF EXISTS transaction_line_pkey;
ALTER TABLE IF EXISTS ONLY public.trade DROP CONSTRAINT IF EXISTS trade_pkey;
ALTER TABLE IF EXISTS ONLY public.token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_token_id_key;
ALTER TABLE IF EXISTS ONLY public.token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_pkey;
ALTER TABLE IF EXISTS ONLY public.system_parameter DROP CONSTRAINT IF EXISTS system_parameter_pkey;
ALTER TABLE IF EXISTS ONLY public.sync_outbox DROP CONSTRAINT IF EXISTS sync_outbox_pkey;
ALTER TABLE IF EXISTS ONLY public.sync_outbox DROP CONSTRAINT IF EXISTS sync_outbox_idempotency_key_key;
ALTER TABLE IF EXISTS ONLY public.sync_log DROP CONSTRAINT IF EXISTS sync_log_pkey;
ALTER TABLE IF EXISTS ONLY public.sync_inbox DROP CONSTRAINT IF EXISTS sync_inbox_pkey;
ALTER TABLE IF EXISTS ONLY public.sync_inbox DROP CONSTRAINT IF EXISTS sync_inbox_idempotency_key_key;
ALTER TABLE IF EXISTS ONLY public.storno_approval DROP CONSTRAINT IF EXISTS storno_approval_pkey;
ALTER TABLE IF EXISTS ONLY public.stock_correction DROP CONSTRAINT IF EXISTS stock_correction_pkey;
ALTER TABLE IF EXISTS ONLY public.stamp_batch DROP CONSTRAINT IF EXISTS stamp_batch_pkey;
ALTER TABLE IF EXISTS ONLY public.stamp_assignment DROP CONSTRAINT IF EXISTS stamp_assignment_pkey;
ALTER TABLE IF EXISTS ONLY public.shipment_request DROP CONSTRAINT IF EXISTS shipment_request_pkey;
ALTER TABLE IF EXISTS ONLY public.shipment_request_item DROP CONSTRAINT IF EXISTS shipment_request_item_pkey;
ALTER TABLE IF EXISTS ONLY public.seal_tracking DROP CONSTRAINT IF EXISTS seal_tracking_pkey;
ALTER TABLE IF EXISTS ONLY public.seal_number DROP CONSTRAINT IF EXISTS seal_number_pkey;
ALTER TABLE IF EXISTS ONLY public.scheduled_task DROP CONSTRAINT IF EXISTS scheduled_task_pkey;
ALTER TABLE IF EXISTS ONLY public.scanned_document DROP CONSTRAINT IF EXISTS scanned_document_pkey;
ALTER TABLE IF EXISTS ONLY public.sanction_screening_log DROP CONSTRAINT IF EXISTS sanction_screening_log_pkey;
ALTER TABLE IF EXISTS ONLY public.sanction_entries DROP CONSTRAINT IF EXISTS sanction_entries_pkey;
ALTER TABLE IF EXISTS ONLY public.rounding_rule DROP CONSTRAINT IF EXISTS rounding_rule_pkey;
ALTER TABLE IF EXISTS ONLY public.role DROP CONSTRAINT IF EXISTS role_pkey;
ALTER TABLE IF EXISTS ONLY public.role_permission DROP CONSTRAINT IF EXISTS role_permission_pkey;
ALTER TABLE IF EXISTS ONLY public.reservation DROP CONSTRAINT IF EXISTS reservation_pkey;
ALTER TABLE IF EXISTS ONLY public.receipt_sequence DROP CONSTRAINT IF EXISTS receipt_sequence_pkey;
ALTER TABLE IF EXISTS ONLY public.receipt DROP CONSTRAINT IF EXISTS receipt_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup DROP CONSTRAINT IF EXISTS rate_workgroup_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_workgroup_branch DROP CONSTRAINT IF EXISTS rate_workgroup_branch_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_template DROP CONSTRAINT IF EXISTS rate_template_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_publication DROP CONSTRAINT IF EXISTS rate_publication_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_history DROP CONSTRAINT IF EXISTS rate_history_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_discount DROP CONSTRAINT IF EXISTS rate_discount_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_category DROP CONSTRAINT IF EXISTS rate_category_pkey;
ALTER TABLE IF EXISTS ONLY public.rate_approval DROP CONSTRAINT IF EXISTS rate_approval_pkey;
ALTER TABLE IF EXISTS ONLY public.prohibited_person DROP CONSTRAINT IF EXISTS prohibited_person_pkey;
ALTER TABLE IF EXISTS ONLY public.prohibited_company DROP CONSTRAINT IF EXISTS prohibited_company_pkey;
ALTER TABLE IF EXISTS ONLY public.profit_log DROP CONSTRAINT IF EXISTS profit_log_pkey;
ALTER TABLE IF EXISTS ONLY public.print_template DROP CONSTRAINT IF EXISTS print_template_pkey;
ALTER TABLE IF EXISTS ONLY public.pos_terminal DROP CONSTRAINT IF EXISTS pos_terminal_pkey;
ALTER TABLE IF EXISTS ONLY public.police_request DROP CONSTRAINT IF EXISTS police_request_pkey;
ALTER TABLE IF EXISTS ONLY public.permission DROP CONSTRAINT IF EXISTS permission_pkey;
ALTER TABLE IF EXISTS ONLY public.packaging_record DROP CONSTRAINT IF EXISTS packaging_record_pkey;
ALTER TABLE IF EXISTS ONLY public.own_company DROP CONSTRAINT IF EXISTS own_company_pkey;
ALTER TABLE IF EXISTS ONLY public.organizational_system_parameter DROP CONSTRAINT IF EXISTS organizational_system_parameter_pkey;
ALTER TABLE IF EXISTS ONLY public.organization DROP CONSTRAINT IF EXISTS organization_pkey;
ALTER TABLE IF EXISTS ONLY public.notification DROP CONSTRAINT IF EXISTS notification_pkey;
ALTER TABLE IF EXISTS ONLY public.nav_closing DROP CONSTRAINT IF EXISTS nav_closing_pkey;
ALTER TABLE IF EXISTS ONLY public.nav_closing_line DROP CONSTRAINT IF EXISTS nav_closing_line_pkey;
ALTER TABLE IF EXISTS ONLY public.monthly_closing_summary DROP CONSTRAINT IF EXISTS monthly_closing_summary_pkey;
ALTER TABLE IF EXISTS ONLY public.monthly_closing DROP CONSTRAINT IF EXISTS monthly_closing_pkey;
ALTER TABLE IF EXISTS ONLY public.mnb_report DROP CONSTRAINT IF EXISTS mnb_report_pkey;
ALTER TABLE IF EXISTS ONLY public.mnb_report_line DROP CONSTRAINT IF EXISTS mnb_report_line_pkey;
ALTER TABLE IF EXISTS ONLY public.mnb_exchange_rate_cache DROP CONSTRAINT IF EXISTS mnb_exchange_rate_cache_pkey;
ALTER TABLE IF EXISTS ONLY public.material_receipt DROP CONSTRAINT IF EXISTS material_receipt_pkey;
ALTER TABLE IF EXISTS ONLY public.material_receipt_line DROP CONSTRAINT IF EXISTS material_receipt_line_pkey;
ALTER TABLE IF EXISTS ONLY public.license DROP CONSTRAINT IF EXISTS license_pkey;
ALTER TABLE IF EXISTS ONLY public.led_display DROP CONSTRAINT IF EXISTS led_display_pkey;
ALTER TABLE IF EXISTS ONLY public.led_display_config DROP CONSTRAINT IF EXISTS led_display_config_pkey;
ALTER TABLE IF EXISTS ONLY public.inventory_summary DROP CONSTRAINT IF EXISTS inventory_summary_pkey;
ALTER TABLE IF EXISTS ONLY public.inventory_regeneration DROP CONSTRAINT IF EXISTS inventory_regeneration_pkey;
ALTER TABLE IF EXISTS ONLY public.inventory_movement DROP CONSTRAINT IF EXISTS inventory_movement_pkey;
ALTER TABLE IF EXISTS ONLY public.initial_fee_config DROP CONSTRAINT IF EXISTS initial_fee_config_pkey;
ALTER TABLE IF EXISTS ONLY public.translation DROP CONSTRAINT IF EXISTS idx_translation_lang_key;
ALTER TABLE IF EXISTS ONLY public.shipment_request DROP CONSTRAINT IF EXISTS idx_shipment_request_number;
ALTER TABLE IF EXISTS ONLY public.seal_number DROP CONSTRAINT IF EXISTS idx_seal_number_unique;
ALTER TABLE IF EXISTS ONLY public.hrk_transaction DROP CONSTRAINT IF EXISTS hrk_transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.handover_sheet DROP CONSTRAINT IF EXISTS handover_sheet_pkey;
ALTER TABLE IF EXISTS ONLY public.handling_fee_transaction DROP CONSTRAINT IF EXISTS handling_fee_transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.handling_fee_decade_report DROP CONSTRAINT IF EXISTS handling_fee_decade_report_pkey;
ALTER TABLE IF EXISTS ONLY public.handling_fee_bracket DROP CONSTRAINT IF EXISTS handling_fee_bracket_pkey;
ALTER TABLE IF EXISTS ONLY public.ftp_sync_log DROP CONSTRAINT IF EXISTS ftp_sync_log_pkey;
ALTER TABLE IF EXISTS ONLY public.flyway_schema_history DROP CONSTRAINT IF EXISTS flyway_schema_history_pk;
ALTER TABLE IF EXISTS ONLY public.feor_code DROP CONSTRAINT IF EXISTS feor_code_pkey;
ALTER TABLE IF EXISTS ONLY public.fee_type DROP CONSTRAINT IF EXISTS fee_type_pkey;
ALTER TABLE IF EXISTS ONLY public.fee_rate DROP CONSTRAINT IF EXISTS fee_rate_pkey;
ALTER TABLE IF EXISTS ONLY public.fee_discount DROP CONSTRAINT IF EXISTS fee_discount_pkey;
ALTER TABLE IF EXISTS ONLY public.exchange_rate_source DROP CONSTRAINT IF EXISTS exchange_rate_source_pkey;
ALTER TABLE IF EXISTS ONLY public.exchange_rate DROP CONSTRAINT IF EXISTS exchange_rate_pkey;
ALTER TABLE IF EXISTS ONLY public.exchange_rate_display DROP CONSTRAINT IF EXISTS exchange_rate_display_pkey;
ALTER TABLE IF EXISTS ONLY public.evening_sync_log DROP CONSTRAINT IF EXISTS evening_sync_log_pkey;
ALTER TABLE IF EXISTS ONLY public.evening_closing DROP CONSTRAINT IF EXISTS evening_closing_pkey;
ALTER TABLE IF EXISTS ONLY public.error_logs DROP CONSTRAINT IF EXISTS error_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.employee DROP CONSTRAINT IF EXISTS employee_pkey;
ALTER TABLE IF EXISTS ONLY public.employee_bank_account DROP CONSTRAINT IF EXISTS employee_bank_account_pkey;
ALTER TABLE IF EXISTS ONLY public.employee_address DROP CONSTRAINT IF EXISTS employee_address_pkey;
ALTER TABLE IF EXISTS ONLY public.email_cache DROP CONSTRAINT IF EXISTS email_cache_pkey;
ALTER TABLE IF EXISTS ONLY public.email_account DROP CONSTRAINT IF EXISTS email_account_pkey;
ALTER TABLE IF EXISTS ONLY public.document DROP CONSTRAINT IF EXISTS document_pkey;
ALTER TABLE IF EXISTS ONLY public.dictionary DROP CONSTRAINT IF EXISTS dictionary_pkey;
ALTER TABLE IF EXISTS ONLY public.denomination DROP CONSTRAINT IF EXISTS denomination_pkey;
ALTER TABLE IF EXISTS ONLY public.denomination_count DROP CONSTRAINT IF EXISTS denomination_count_pkey;
ALTER TABLE IF EXISTS ONLY public.denomination_balance DROP CONSTRAINT IF EXISTS denomination_balance_pkey;
ALTER TABLE IF EXISTS ONLY public.decade_report DROP CONSTRAINT IF EXISTS decade_report_pkey;
ALTER TABLE IF EXISTS ONLY public.decade_report_line DROP CONSTRAINT IF EXISTS decade_report_line_pkey;
ALTER TABLE IF EXISTS ONLY public.data_import_jobs DROP CONSTRAINT IF EXISTS data_import_jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.data_collection DROP CONSTRAINT IF EXISTS data_collection_pkey;
ALTER TABLE IF EXISTS ONLY public.darius_report_line DROP CONSTRAINT IF EXISTS darius_report_line_pkey;
ALTER TABLE IF EXISTS ONLY public.darius_daily_report DROP CONSTRAINT IF EXISTS darius_daily_report_pkey;
ALTER TABLE IF EXISTS ONLY public.daily_session DROP CONSTRAINT IF EXISTS daily_session_pkey;
ALTER TABLE IF EXISTS ONLY public.daily_report DROP CONSTRAINT IF EXISTS daily_report_pkey;
ALTER TABLE IF EXISTS ONLY public.daily_checklist DROP CONSTRAINT IF EXISTS daily_checklist_pkey;
ALTER TABLE IF EXISTS ONLY public.daily_checklist_item DROP CONSTRAINT IF EXISTS daily_checklist_item_pkey;
ALTER TABLE IF EXISTS ONLY public.daily_balance DROP CONSTRAINT IF EXISTS daily_balance_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_screening_log DROP CONSTRAINT IF EXISTS customer_screening_log_pkey;
ALTER TABLE IF EXISTS ONLY public.customer_restriction DROP CONSTRAINT IF EXISTS customer_restriction_pkey;
ALTER TABLE IF EXISTS ONLY public.customer DROP CONSTRAINT IF EXISTS customer_pkey;
ALTER TABLE IF EXISTS ONLY public.currency_stock DROP CONSTRAINT IF EXISTS currency_stock_pkey;
ALTER TABLE IF EXISTS ONLY public.currency DROP CONSTRAINT IF EXISTS currency_pkey;
ALTER TABLE IF EXISTS ONLY public.currency_group DROP CONSTRAINT IF EXISTS currency_group_pkey;
ALTER TABLE IF EXISTS ONLY public.contribution DROP CONSTRAINT IF EXISTS contribution_pkey;
ALTER TABLE IF EXISTS ONLY public.competitor_rates DROP CONSTRAINT IF EXISTS competitor_rates_pkey;
ALTER TABLE IF EXISTS ONLY public.competitor DROP CONSTRAINT IF EXISTS competitor_pkey;
ALTER TABLE IF EXISTS ONLY public.company DROP CONSTRAINT IF EXISTS company_pkey;
ALTER TABLE IF EXISTS ONLY public.commission_rule DROP CONSTRAINT IF EXISTS commission_rule_pkey;
ALTER TABLE IF EXISTS ONLY public.commission_rate DROP CONSTRAINT IF EXISTS commission_rate_pkey;
ALTER TABLE IF EXISTS ONLY public.commission_calculation DROP CONSTRAINT IF EXISTS commission_calculation_pkey;
ALTER TABLE IF EXISTS ONLY public.collected_transaction DROP CONSTRAINT IF EXISTS collected_transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.collected_inventory DROP CONSTRAINT IF EXISTS collected_inventory_pkey;
ALTER TABLE IF EXISTS ONLY public.closing_wizard_step DROP CONSTRAINT IF EXISTS closing_wizard_step_pkey;
ALTER TABLE IF EXISTS ONLY public.closing_wizard DROP CONSTRAINT IF EXISTS closing_wizard_pkey;
ALTER TABLE IF EXISTS ONLY public.closing_control DROP CONSTRAINT IF EXISTS closing_control_pkey;
ALTER TABLE IF EXISTS ONLY public.circular_sequence DROP CONSTRAINT IF EXISTS circular_sequence_pkey;
ALTER TABLE IF EXISTS ONLY public.circular_sequence DROP CONSTRAINT IF EXISTS circular_sequence_company_id_prefix_key;
ALTER TABLE IF EXISTS ONLY public.circular DROP CONSTRAINT IF EXISTS circular_pkey;
ALTER TABLE IF EXISTS ONLY public.circular_acknowledgment DROP CONSTRAINT IF EXISTS circular_acknowledgment_pkey;
ALTER TABLE IF EXISTS ONLY public.circular_acknowledgment DROP CONSTRAINT IF EXISTS circular_acknowledgment_circular_id_worker_id_key;
ALTER TABLE IF EXISTS ONLY public.chain_of_custody_record DROP CONSTRAINT IF EXISTS chain_of_custody_record_pkey;
ALTER TABLE IF EXISTS ONLY public.cash_register_event DROP CONSTRAINT IF EXISTS cash_register_event_pkey;
ALTER TABLE IF EXISTS ONLY public.cash_desk_break DROP CONSTRAINT IF EXISTS cash_desk_break_pkey;
ALTER TABLE IF EXISTS ONLY public.cash_balance DROP CONSTRAINT IF EXISTS cash_balance_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_transaction_link DROP CONSTRAINT IF EXISTS camera_transaction_link_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_segment_hash DROP CONSTRAINT IF EXISTS camera_segment_hash_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_recording DROP CONSTRAINT IF EXISTS camera_recording_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_export_request DROP CONSTRAINT IF EXISTS camera_export_request_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_config DROP CONSTRAINT IF EXISTS camera_config_pkey;
ALTER TABLE IF EXISTS ONLY public.camera_access_log DROP CONSTRAINT IF EXISTS camera_access_log_pkey;
ALTER TABLE IF EXISTS ONLY public.branch_status DROP CONSTRAINT IF EXISTS branch_status_pkey;
ALTER TABLE IF EXISTS ONLY public.branch DROP CONSTRAINT IF EXISTS branch_pkey;
ALTER TABLE IF EXISTS ONLY public.branch_group DROP CONSTRAINT IF EXISTS branch_group_pkey;
ALTER TABLE IF EXISTS ONLY public.backup_record DROP CONSTRAINT IF EXISTS backup_record_pkey;
ALTER TABLE IF EXISTS ONLY public.authorized_representative DROP CONSTRAINT IF EXISTS authorized_representative_pkey;
ALTER TABLE IF EXISTS ONLY public.authorization_log DROP CONSTRAINT IF EXISTS authorization_log_pkey;
ALTER TABLE IF EXISTS ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_pkey;
ALTER TABLE IF EXISTS ONLY public.archived_transactions DROP CONSTRAINT IF EXISTS archived_transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.archived_monthly_transaction DROP CONSTRAINT IF EXISTS archived_monthly_transaction_pkey;
ALTER TABLE IF EXISTS ONLY public.archive_task DROP CONSTRAINT IF EXISTS archive_task_pkey;
ALTER TABLE IF EXISTS ONLY public.anonymous_report DROP CONSTRAINT IF EXISTS anonymous_report_pkey;
ALTER TABLE IF EXISTS ONLY public.aml_threshold DROP CONSTRAINT IF EXISTS aml_threshold_pkey;
ALTER TABLE IF EXISTS ONLY public.aml_report DROP CONSTRAINT IF EXISTS aml_report_pkey;
ALTER TABLE IF EXISTS public.worker_session ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.worker_role_def ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.worker_role_assignment ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.worker ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_transfer ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_territory ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_distribution_line ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_distribution ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_collection ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.vault_bank_transaction ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.translation ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transfer_document ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transfer ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction_line ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.transaction ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.token_blacklist ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.stock_correction ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.seal_tracking ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rounding_rule ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.reservation ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.receipt_sequence ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rate_history ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.profit_log ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.monthly_closing_summary ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.mnb_exchange_rate_cache ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.material_receipt_line ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.material_receipt ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.inventory_summary ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.inventory_regeneration ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.inventory_movement ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.initial_fee_config ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.handling_fee_bracket ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.feor_code ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.exchange_rate_source ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.exchange_rate ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.evening_sync_log ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.employee_bank_account ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.employee_address ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.employee ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.denomination ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.daily_session ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.daily_report ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.daily_balance ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.customer ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.currency_stock ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.currency ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.circular_sequence ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.circular_acknowledgment ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.circular ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.cash_balance ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.archived_transactions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.archived_monthly_transaction ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS public.wu_transactions;
DROP TABLE IF EXISTS public.wu_customers;
DROP TABLE IF EXISTS public.wu_balances;
DROP TABLE IF EXISTS public.workstation;
DROP SEQUENCE IF EXISTS public.worker_session_id_seq;
DROP TABLE IF EXISTS public.worker_session;
DROP TABLE IF EXISTS public.worker_role_permission;
DROP SEQUENCE IF EXISTS public.worker_role_def_id_seq;
DROP TABLE IF EXISTS public.worker_role_def;
DROP SEQUENCE IF EXISTS public.worker_role_assignment_id_seq;
DROP TABLE IF EXISTS public.worker_role_assignment;
DROP SEQUENCE IF EXISTS public.worker_id_seq;
DROP TABLE IF EXISTS public.worker_competition_entry;
DROP TABLE IF EXISTS public.worker_competition;
DROP TABLE IF EXISTS public.worker_commission;
DROP TABLE IF EXISTS public.worker_break;
DROP TABLE IF EXISTS public.worker_attendance;
DROP TABLE IF EXISTS public.worker;
DROP SEQUENCE IF EXISTS public.vault_transfer_seq;
DROP SEQUENCE IF EXISTS public.vault_transfer_id_seq;
DROP TABLE IF EXISTS public.vault_transfer;
DROP SEQUENCE IF EXISTS public.vault_territory_id_seq;
DROP TABLE IF EXISTS public.vault_territory;
DROP SEQUENCE IF EXISTS public.vault_distribution_line_id_seq;
DROP TABLE IF EXISTS public.vault_distribution_line;
DROP SEQUENCE IF EXISTS public.vault_distribution_id_seq;
DROP TABLE IF EXISTS public.vault_distribution;
DROP SEQUENCE IF EXISTS public.vault_collection_id_seq;
DROP TABLE IF EXISTS public.vault_collection;
DROP SEQUENCE IF EXISTS public.vault_bank_transaction_id_seq;
DROP TABLE IF EXISTS public.vault_bank_transaction;
DROP SEQUENCE IF EXISTS public.translation_id_seq;
DROP TABLE IF EXISTS public.translation;
DROP SEQUENCE IF EXISTS public.transfer_id_seq;
DROP SEQUENCE IF EXISTS public.transfer_document_id_seq;
DROP TABLE IF EXISTS public.transfer_document;
DROP TABLE IF EXISTS public.transfer;
DROP SEQUENCE IF EXISTS public.transaction_line_id_seq;
DROP TABLE IF EXISTS public.transaction_line;
DROP SEQUENCE IF EXISTS public.transaction_id_seq;
DROP TABLE IF EXISTS public.transaction;
DROP TABLE IF EXISTS public.trade;
DROP SEQUENCE IF EXISTS public.token_blacklist_id_seq;
DROP TABLE IF EXISTS public.token_blacklist;
DROP TABLE IF EXISTS public.system_parameter;
DROP TABLE IF EXISTS public.sync_outbox;
DROP TABLE IF EXISTS public.sync_log;
DROP TABLE IF EXISTS public.sync_inbox;
DROP TABLE IF EXISTS public.storno_approval;
DROP SEQUENCE IF EXISTS public.stock_correction_id_seq;
DROP TABLE IF EXISTS public.stock_correction;
DROP TABLE IF EXISTS public.stamp_batch;
DROP TABLE IF EXISTS public.stamp_assignment;
DROP TABLE IF EXISTS public.shipment_request_item;
DROP TABLE IF EXISTS public.shipment_request;
DROP SEQUENCE IF EXISTS public.seal_tracking_id_seq;
DROP TABLE IF EXISTS public.seal_tracking;
DROP TABLE IF EXISTS public.seal_number;
DROP TABLE IF EXISTS public.scheduled_task;
DROP TABLE IF EXISTS public.scanned_document;
DROP TABLE IF EXISTS public.sanction_screening_log;
DROP TABLE IF EXISTS public.sanction_entries;
DROP SEQUENCE IF EXISTS public.rounding_rule_id_seq;
DROP TABLE IF EXISTS public.rounding_rule;
DROP TABLE IF EXISTS public.role_permission;
DROP TABLE IF EXISTS public.role;
DROP SEQUENCE IF EXISTS public.reservation_id_seq;
DROP TABLE IF EXISTS public.reservation;
DROP SEQUENCE IF EXISTS public.receipt_sequence_id_seq;
DROP TABLE IF EXISTS public.receipt_sequence;
DROP TABLE IF EXISTS public.receipt;
DROP TABLE IF EXISTS public.rate_workgroup_branch;
DROP TABLE IF EXISTS public.rate_workgroup;
DROP TABLE IF EXISTS public.rate_template;
DROP TABLE IF EXISTS public.rate_publication;
DROP SEQUENCE IF EXISTS public.rate_history_id_seq;
DROP TABLE IF EXISTS public.rate_history;
DROP TABLE IF EXISTS public.rate_discount;
DROP TABLE IF EXISTS public.rate_category;
DROP TABLE IF EXISTS public.rate_approval;
DROP TABLE IF EXISTS public.prohibited_person;
DROP TABLE IF EXISTS public.prohibited_company;
DROP SEQUENCE IF EXISTS public.profit_log_id_seq;
DROP TABLE IF EXISTS public.profit_log;
DROP TABLE IF EXISTS public.print_template;
DROP TABLE IF EXISTS public.pos_terminal;
DROP TABLE IF EXISTS public.police_request;
DROP TABLE IF EXISTS public.permission;
DROP TABLE IF EXISTS public.packaging_record;
DROP TABLE IF EXISTS public.own_company;
DROP TABLE IF EXISTS public.organizational_system_parameter;
DROP TABLE IF EXISTS public.organization;
DROP TABLE IF EXISTS public.notification;
DROP TABLE IF EXISTS public.nav_closing_line;
DROP TABLE IF EXISTS public.nav_closing;
DROP SEQUENCE IF EXISTS public.monthly_closing_summary_id_seq;
DROP TABLE IF EXISTS public.monthly_closing_summary;
DROP TABLE IF EXISTS public.monthly_closing;
DROP TABLE IF EXISTS public.mnb_report_line;
DROP TABLE IF EXISTS public.mnb_report;
DROP SEQUENCE IF EXISTS public.mnb_exchange_rate_cache_id_seq;
DROP TABLE IF EXISTS public.mnb_exchange_rate_cache;
DROP SEQUENCE IF EXISTS public.material_receipt_seq;
DROP SEQUENCE IF EXISTS public.material_receipt_line_id_seq;
DROP TABLE IF EXISTS public.material_receipt_line;
DROP SEQUENCE IF EXISTS public.material_receipt_id_seq;
DROP TABLE IF EXISTS public.material_receipt;
DROP TABLE IF EXISTS public.license;
DROP TABLE IF EXISTS public.led_display_config;
DROP TABLE IF EXISTS public.led_display;
DROP SEQUENCE IF EXISTS public.inventory_summary_id_seq;
DROP TABLE IF EXISTS public.inventory_summary;
DROP SEQUENCE IF EXISTS public.inventory_regeneration_id_seq;
DROP TABLE IF EXISTS public.inventory_regeneration;
DROP SEQUENCE IF EXISTS public.inventory_movement_id_seq;
DROP TABLE IF EXISTS public.inventory_movement;
DROP SEQUENCE IF EXISTS public.initial_fee_config_id_seq;
DROP TABLE IF EXISTS public.initial_fee_config;
DROP TABLE IF EXISTS public.hrk_transaction;
DROP TABLE IF EXISTS public.handover_sheet;
DROP TABLE IF EXISTS public.handling_fee_transaction;
DROP TABLE IF EXISTS public.handling_fee_decade_report;
DROP SEQUENCE IF EXISTS public.handling_fee_bracket_id_seq;
DROP TABLE IF EXISTS public.handling_fee_bracket;
DROP TABLE IF EXISTS public.ftp_sync_log;
DROP TABLE IF EXISTS public.flyway_schema_history;
DROP SEQUENCE IF EXISTS public.feor_code_id_seq;
DROP TABLE IF EXISTS public.feor_code;
DROP TABLE IF EXISTS public.fee_type;
DROP TABLE IF EXISTS public.fee_rate;
DROP TABLE IF EXISTS public.fee_discount;
DROP SEQUENCE IF EXISTS public.exchange_rate_source_id_seq;
DROP TABLE IF EXISTS public.exchange_rate_source;
DROP SEQUENCE IF EXISTS public.exchange_rate_id_seq;
DROP TABLE IF EXISTS public.exchange_rate_display;
DROP TABLE IF EXISTS public.exchange_rate;
DROP SEQUENCE IF EXISTS public.evening_sync_log_id_seq;
DROP TABLE IF EXISTS public.evening_sync_log;
DROP TABLE IF EXISTS public.evening_closing;
DROP TABLE IF EXISTS public.error_logs;
DROP SEQUENCE IF EXISTS public.employee_id_seq;
DROP SEQUENCE IF EXISTS public.employee_bank_account_id_seq;
DROP TABLE IF EXISTS public.employee_bank_account;
DROP SEQUENCE IF EXISTS public.employee_address_id_seq;
DROP TABLE IF EXISTS public.employee_address;
DROP TABLE IF EXISTS public.employee;
DROP TABLE IF EXISTS public.email_cache;
DROP TABLE IF EXISTS public.email_account;
DROP TABLE IF EXISTS public.document;
DROP TABLE IF EXISTS public.dictionary;
DROP SEQUENCE IF EXISTS public.denomination_id_seq;
DROP TABLE IF EXISTS public.denomination_count;
DROP TABLE IF EXISTS public.denomination_balance;
DROP TABLE IF EXISTS public.denomination;
DROP TABLE IF EXISTS public.decade_report_line;
DROP TABLE IF EXISTS public.decade_report;
DROP TABLE IF EXISTS public.data_import_jobs;
DROP TABLE IF EXISTS public.data_collection;
DROP TABLE IF EXISTS public.darius_report_line;
DROP TABLE IF EXISTS public.darius_daily_report;
DROP SEQUENCE IF EXISTS public.daily_session_id_seq;
DROP TABLE IF EXISTS public.daily_session;
DROP SEQUENCE IF EXISTS public.daily_report_id_seq;
DROP TABLE IF EXISTS public.daily_report;
DROP TABLE IF EXISTS public.daily_checklist_item;
DROP TABLE IF EXISTS public.daily_checklist;
DROP SEQUENCE IF EXISTS public.daily_balance_id_seq;
DROP TABLE IF EXISTS public.daily_balance;
DROP TABLE IF EXISTS public.customer_screening_log;
DROP TABLE IF EXISTS public.customer_restriction;
DROP SEQUENCE IF EXISTS public.customer_id_seq;
DROP TABLE IF EXISTS public.customer;
DROP SEQUENCE IF EXISTS public.currency_stock_id_seq;
DROP TABLE IF EXISTS public.currency_stock;
DROP SEQUENCE IF EXISTS public.currency_id_seq;
DROP TABLE IF EXISTS public.currency_group;
DROP TABLE IF EXISTS public.currency;
DROP TABLE IF EXISTS public.contribution;
DROP TABLE IF EXISTS public.competitor_rates;
DROP TABLE IF EXISTS public.competitor;
DROP TABLE IF EXISTS public.company;
DROP TABLE IF EXISTS public.commission_rule;
DROP TABLE IF EXISTS public.commission_rate;
DROP TABLE IF EXISTS public.commission_calculation;
DROP TABLE IF EXISTS public.collected_transaction;
DROP TABLE IF EXISTS public.collected_inventory;
DROP TABLE IF EXISTS public.closing_wizard_step;
DROP TABLE IF EXISTS public.closing_wizard;
DROP TABLE IF EXISTS public.closing_control;
DROP SEQUENCE IF EXISTS public.circular_sequence_id_seq;
DROP TABLE IF EXISTS public.circular_sequence;
DROP SEQUENCE IF EXISTS public.circular_id_seq;
DROP SEQUENCE IF EXISTS public.circular_acknowledgment_id_seq;
DROP TABLE IF EXISTS public.circular_acknowledgment;
DROP TABLE IF EXISTS public.circular;
DROP TABLE IF EXISTS public.chain_of_custody_record;
DROP TABLE IF EXISTS public.cash_register_event;
DROP TABLE IF EXISTS public.cash_desk_break;
DROP SEQUENCE IF EXISTS public.cash_balance_id_seq;
DROP TABLE IF EXISTS public.cash_balance;
DROP TABLE IF EXISTS public.camera_transaction_link;
DROP TABLE IF EXISTS public.camera_segment_hash;
DROP TABLE IF EXISTS public.camera_recording;
DROP TABLE IF EXISTS public.camera_export_request;
DROP TABLE IF EXISTS public.camera_config;
DROP TABLE IF EXISTS public.camera_access_log;
DROP TABLE IF EXISTS public.branch_status;
DROP TABLE IF EXISTS public.branch_group_branches;
DROP TABLE IF EXISTS public.branch_group;
DROP TABLE IF EXISTS public.branch;
DROP TABLE IF EXISTS public.backup_record;
DROP TABLE IF EXISTS public.authorized_representative;
DROP TABLE IF EXISTS public.authorization_log;
DROP TABLE IF EXISTS public.audit_log;
DROP SEQUENCE IF EXISTS public.archived_transactions_id_seq;
DROP TABLE IF EXISTS public.archived_transactions;
DROP SEQUENCE IF EXISTS public.archived_monthly_transaction_id_seq;
DROP TABLE IF EXISTS public.archived_monthly_transaction;
DROP TABLE IF EXISTS public.archive_task;
DROP TABLE IF EXISTS public.anonymous_report;
DROP TABLE IF EXISTS public.aml_threshold;
DROP TABLE IF EXISTS public.aml_report;
DROP EXTENSION IF EXISTS vector;
DROP EXTENSION IF EXISTS pgcrypto;
-- *not* dropping schema, since initdb creates it
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: aml_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aml_report (
    id uuid NOT NULL,
    acknowledged_at timestamp(6) without time zone,
    amount_huf numeric(18,2),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100),
    currency_code character varying(3),
    customer_id character varying(50),
    customer_name character varying(200),
    document_number character varying(50),
    document_type character varying(30),
    external_reference character varying(100),
    original_amount numeric(18,2),
    report_type character varying(30) NOT NULL,
    reviewed_at timestamp(6) without time zone,
    reviewed_by character varying(100),
    risk_level character varying(20) NOT NULL,
    status character varying(30) NOT NULL,
    submitted_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    worker_notes text,
    company_id uuid NOT NULL,
    transaction_id bigint,
    CONSTRAINT aml_report_report_type_check CHECK (((report_type)::text = ANY ((ARRAY['STANDARD'::character varying, 'ENHANCED'::character varying, 'SUSPICIOUS'::character varying, 'THRESHOLD'::character varying])::text[]))),
    CONSTRAINT aml_report_risk_level_check CHECK (((risk_level)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[]))),
    CONSTRAINT aml_report_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'ACKNOWLEDGED'::character varying, 'FLAGGED'::character varying])::text[])))
);


--
-- Name: aml_threshold; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.aml_threshold (
    id uuid NOT NULL,
    amount_huf numeric(18,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description character varying(500),
    is_active boolean NOT NULL,
    threshold_type character varying(30) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: anonymous_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anonymous_report (
    id uuid NOT NULL,
    assigned_to_id bigint,
    description text,
    report_type character varying(50) NOT NULL,
    reported_at timestamp(6) without time zone NOT NULL,
    resolution text,
    status character varying(20) NOT NULL,
    subject character varying(200) NOT NULL,
    CONSTRAINT anonymous_report_status_check CHECK (((status)::text = ANY ((ARRAY['NEW'::character varying, 'IN_PROGRESS'::character varying, 'RESOLVED'::character varying, 'CLOSED'::character varying])::text[])))
);


--
-- Name: archive_task; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archive_task (
    id uuid NOT NULL,
    archive_location character varying(500),
    completed_at timestamp(6) without time zone,
    criteria text,
    entity_type character varying(100) NOT NULL,
    started_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    task_type character varying(100) NOT NULL,
    CONSTRAINT archive_task_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'RUNNING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying])::text[])))
);


--
-- Name: archived_monthly_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_monthly_transaction (
    id bigint NOT NULL,
    monthly_closing_id bigint NOT NULL,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    original_tx_id bigint,
    transaction_date date NOT NULL,
    transaction_type character varying(30) NOT NULL,
    currency_code character varying(3) NOT NULL,
    currency_amount numeric(18,2) NOT NULL,
    huf_amount numeric(18,2) NOT NULL,
    exchange_rate numeric(18,6),
    handling_fee numeric(18,2),
    customer_id character varying(50),
    worker_id bigint,
    archived_at timestamp without time zone DEFAULT now() NOT NULL,
    year_month character varying(7) NOT NULL
);


--
-- Name: archived_monthly_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_monthly_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_monthly_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_monthly_transaction_id_seq OWNED BY public.archived_monthly_transaction.id;


--
-- Name: archived_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.archived_transactions (
    id bigint NOT NULL,
    amount numeric(18,2),
    archive_month character varying(7) NOT NULL,
    archive_status character varying(20),
    archived_at timestamp(6) without time zone NOT NULL,
    archived_by character varying(100),
    branch_id uuid,
    currency_code character varying(3),
    customer_id character varying(50),
    customer_name character varying(200),
    document_number character varying(50),
    exchange_rate numeric(18,6),
    handling_fee numeric(18,2),
    huf_amount numeric(18,2),
    original_date timestamp(6) without time zone,
    original_id bigint NOT NULL,
    receipt_number character varying(20),
    rounding_amount numeric(18,2),
    transaction_type character varying(30),
    worker_id bigint,
    company_id uuid NOT NULL
);


--
-- Name: archived_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.archived_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: archived_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.archived_transactions_id_seq OWNED BY public.archived_transactions.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id uuid NOT NULL,
    action character varying(50) NOT NULL,
    branch_id character varying(50),
    branch_name character varying(100),
    changes text,
    created_at timestamp(6) without time zone NOT NULL,
    entity_id character varying(50),
    entity_type character varying(50) NOT NULL,
    ip_address character varying(50),
    new_value text,
    old_value text,
    reason character varying(1000),
    user_agent character varying(500),
    user_id character varying(50),
    user_name character varying(100),
    company_id uuid
);


--
-- Name: authorization_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorization_log (
    id uuid NOT NULL,
    action character varying(100) NOT NULL,
    performed_at timestamp(6) without time zone NOT NULL,
    performed_by_worker_id bigint NOT NULL,
    representative_id uuid NOT NULL,
    transaction_id bigint
);


--
-- Name: authorized_representative; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.authorized_representative (
    id uuid NOT NULL,
    authorization_end date,
    authorization_start date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    customer_id bigint NOT NULL,
    is_active boolean NOT NULL,
    representative_document_number character varying(50) NOT NULL,
    representative_document_type character varying(50) NOT NULL,
    representative_name character varying(200) NOT NULL
);


--
-- Name: backup_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backup_record (
    id uuid NOT NULL,
    backup_type character varying(20) NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(100),
    file_path character varying(500),
    file_size_bytes bigint,
    started_at timestamp(6) without time zone NOT NULL,
    status character varying(20) NOT NULL,
    CONSTRAINT backup_record_backup_type_check CHECK (((backup_type)::text = ANY ((ARRAY['FULL'::character varying, 'INCREMENTAL'::character varying, 'TABLES_ONLY'::character varying])::text[]))),
    CONSTRAINT backup_record_status_check CHECK (((status)::text = ANY ((ARRAY['RUNNING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying])::text[])))
);


--
-- Name: branch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch (
    id uuid NOT NULL,
    address text NOT NULL,
    bank_code character varying(20) NOT NULL,
    city character varying(100) NOT NULL,
    code character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    denomination_rule_id uuid,
    email character varying(255),
    is_active boolean,
    name character varying(255) NOT NULL,
    opening_date date NOT NULL,
    phone character varying(50),
    updated_at timestamp(6) without time zone,
    vault_territory_id integer,
    zip_code character varying(10) NOT NULL,
    branch_status_did uuid NOT NULL,
    branch_type_did uuid NOT NULL,
    company_id uuid NOT NULL,
    country_did uuid NOT NULL,
    parent_branch_id uuid,
    region_code character varying(10)
);


--
-- Name: COLUMN branch.region_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.branch.region_code IS 'Legacy körzet kód (KESZLEX): 10,20,40,50,63,75,120,145';


--
-- Name: branch_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_group (
    id uuid NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    group_type_did bigint,
    is_active boolean NOT NULL,
    name character varying(200) NOT NULL,
    parent_group_id uuid,
    updated_at timestamp(6) without time zone
);


--
-- Name: branch_group_branches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_group_branches (
    branch_group_id uuid NOT NULL,
    branch_id uuid
);


--
-- Name: branch_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.branch_status (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    daily_transaction_count integer NOT NULL,
    daily_volume_huf numeric(18,2) NOT NULL,
    is_online boolean NOT NULL,
    last_heartbeat timestamp(6) without time zone,
    last_sync timestamp(6) without time zone,
    last_transaction_at timestamp(6) without time zone,
    open_alerts integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: camera_access_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_access_log (
    id uuid NOT NULL,
    action character varying(30) NOT NULL,
    created_at timestamp(6) without time zone,
    ip_address character varying(45),
    worker_id bigint NOT NULL,
    recording_id uuid
);


--
-- Name: camera_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_config (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    camera_id character varying(50) NOT NULL,
    camera_name character varying(100),
    created_at timestamp(6) without time zone,
    device_index integer,
    enabled boolean,
    fps integer,
    jpeg_quality integer,
    local_storage_path character varying(500),
    resolution_height integer,
    resolution_width integer
);


--
-- Name: camera_export_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_export_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    camera_id character varying(50),
    period_from timestamp without time zone NOT NULL,
    period_to timestamp without time zone NOT NULL,
    reason text NOT NULL,
    reference_number character varying(100),
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    requested_by character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    approved_by character varying(100),
    approved_at timestamp without time zone,
    rejection_reason text,
    export_path character varying(500),
    export_size_bytes bigint,
    manifest_hash character varying(64),
    completed_at timestamp without time zone,
    error_message text
);


--
-- Name: camera_recording; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_recording (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    camera_id character varying(50) NOT NULL,
    created_at timestamp(6) without time zone,
    end_time timestamp(6) without time zone,
    expires_at date NOT NULL,
    file_size_bytes bigint,
    local_file_path character varying(500),
    server_file_path character varying(500),
    start_time timestamp(6) without time zone NOT NULL,
    status character varying(255),
    upload_attempts integer,
    uploaded_to_server boolean,
    CONSTRAINT camera_recording_status_check CHECK (((status)::text = ANY ((ARRAY['RECORDING'::character varying, 'COMPLETED'::character varying, 'UPLOADED'::character varying, 'EXPIRED'::character varying, 'ERROR'::character varying])::text[])))
);


--
-- Name: camera_segment_hash; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_segment_hash (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recording_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    camera_id character varying(50) NOT NULL,
    sequence_number integer NOT NULL,
    file_hash character varying(64) NOT NULL,
    previous_hash character varying(64) NOT NULL,
    chain_hash character varying(64) NOT NULL,
    file_path character varying(500),
    file_size_bytes bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: camera_transaction_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.camera_transaction_link (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone,
    frame_offset_seconds integer,
    receipt_number character varying(50),
    transaction_id uuid,
    transaction_time timestamp(6) without time zone NOT NULL,
    recording_id uuid NOT NULL
);


--
-- Name: cash_balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_balance (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    current_balance numeric(15,2) NOT NULL,
    last_transaction_at timestamp(6) without time zone,
    max_balance numeric(15,2),
    min_balance numeric(15,2),
    opening_balance numeric(15,2),
    updated_at timestamp(6) without time zone,
    version bigint DEFAULT 0 NOT NULL,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    currency_id bigint NOT NULL
);


--
-- Name: cash_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cash_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cash_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cash_balance_id_seq OWNED BY public.cash_balance.id;


--
-- Name: cash_desk_break; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_desk_break (
    id uuid NOT NULL,
    break_end timestamp(6) without time zone,
    break_start timestamp(6) without time zone NOT NULL,
    break_type character varying(50) NOT NULL,
    cash_desk_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_active boolean NOT NULL,
    reason character varying(500)
);


--
-- Name: cash_register_event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cash_register_event (
    id uuid NOT NULL,
    amount numeric(18,2),
    amount_huf numeric(18,2),
    cash_register_id character varying(50),
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3),
    event_timestamp timestamp(6) without time zone NOT NULL,
    event_type character varying(30) NOT NULL,
    raw_response text,
    receipt_number character varying(100),
    tax_number character varying(20),
    branch_id uuid NOT NULL,
    CONSTRAINT cash_register_event_event_type_check CHECK (((event_type)::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSE'::character varying, 'RECEIPT'::character varying, 'STORNO'::character varying, 'X_REPORT'::character varying, 'Z_REPORT'::character varying])::text[])))
);


--
-- Name: chain_of_custody_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chain_of_custody_record (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    export_request_id uuid,
    branch_id uuid NOT NULL,
    camera_id character varying(50),
    event_type character varying(30) NOT NULL,
    actor character varying(100) NOT NULL,
    event_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    details text,
    period_from timestamp without time zone,
    period_to timestamp without time zone,
    source_ip character varying(45),
    manifest_hash character varying(64)
);


--
-- Name: circular; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.circular (
    id bigint NOT NULL,
    acknowledged boolean NOT NULL,
    acknowledged_at timestamp(6) without time zone,
    attachment_filename character varying(255),
    attachment_mime_type character varying(100),
    attachment_path character varying(500),
    circular_type character varying(30) NOT NULL,
    content text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    priority character varying(20) NOT NULL,
    registration_number character varying(50),
    target character varying(30) NOT NULL,
    target_branch_id uuid,
    target_company_id integer,
    title character varying(200) NOT NULL,
    urgent boolean NOT NULL,
    valid_from date,
    valid_to date,
    created_by_id bigint NOT NULL,
    company_id uuid,
    archived boolean DEFAULT false NOT NULL,
    archived_at timestamp without time zone,
    archive_year integer,
    category character varying(20) DEFAULT 'GENERAL'::character varying NOT NULL,
    attachment_size bigint,
    CONSTRAINT circular_circular_type_check CHECK (((circular_type)::text = ANY ((ARRAY['GENERAL'::character varying, 'REGULATION'::character varying, 'RATE_POLICY'::character varying, 'SECURITY_ALERT'::character varying, 'INVENTORY'::character varying, 'HR'::character varying, 'TECHNICAL'::character varying, 'BEST_CHANGE'::character varying, 'ZALOG'::character varying, 'MANAGEMENT'::character varying, 'APPOINTMENT'::character varying, 'NEW_YEAR'::character varying, 'YEAR_END'::character varying, 'MONTHLY_SUMMARY'::character varying, 'VIP_NOTICE'::character varying, 'AUDIT_NOTICE'::character varying, 'TRAINING'::character varying])::text[]))),
    CONSTRAINT circular_priority_check CHECK (((priority)::text = ANY ((ARRAY['LOW'::character varying, 'NORMAL'::character varying, 'HIGH'::character varying, 'URGENT'::character varying])::text[]))),
    CONSTRAINT circular_target_check CHECK (((target)::text = ANY ((ARRAY['ALL_BRANCHES'::character varying, 'COMPANY_SPECIFIC'::character varying, 'SINGLE_BRANCH'::character varying, 'MANAGERS_ONLY'::character varying])::text[])))
);


--
-- Name: circular_acknowledgment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.circular_acknowledgment (
    id bigint NOT NULL,
    circular_id bigint NOT NULL,
    worker_id bigint NOT NULL,
    acknowledged_at timestamp without time zone DEFAULT now() NOT NULL,
    ip_address character varying(45)
);


--
-- Name: circular_acknowledgment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.circular_acknowledgment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: circular_acknowledgment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.circular_acknowledgment_id_seq OWNED BY public.circular_acknowledgment.id;


--
-- Name: circular_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.circular_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: circular_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.circular_id_seq OWNED BY public.circular.id;


--
-- Name: circular_sequence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.circular_sequence (
    id integer NOT NULL,
    company_id uuid NOT NULL,
    prefix character varying(10) NOT NULL,
    last_number integer DEFAULT 0 NOT NULL
);


--
-- Name: circular_sequence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.circular_sequence_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: circular_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.circular_sequence_id_seq OWNED BY public.circular_sequence.id;


--
-- Name: closing_control; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.closing_control (
    id uuid NOT NULL,
    alert_level character varying(20) NOT NULL,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    control_date date NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    daily_closing_done boolean NOT NULL,
    evening_closing_done boolean NOT NULL,
    last_transaction_at timestamp(6) without time zone,
    nav_closing_done boolean NOT NULL,
    notes text,
    updated_at timestamp(6) without time zone
);


--
-- Name: closing_wizard; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.closing_wizard (
    id uuid NOT NULL,
    cash_desk_id uuid,
    closing_date date NOT NULL,
    closing_type character varying(20) NOT NULL,
    completed_at timestamp(6) without time zone,
    current_step integer NOT NULL,
    notes character varying(1000),
    started_at timestamp(6) without time zone NOT NULL,
    total_steps integer NOT NULL,
    wizard_status character varying(20) NOT NULL,
    branch_id uuid NOT NULL,
    completed_by_worker_id bigint,
    started_by_worker_id bigint NOT NULL,
    CONSTRAINT closing_wizard_closing_type_check CHECK (((closing_type)::text = ANY ((ARRAY['DAILY'::character varying, 'POS'::character varying, 'DECADE'::character varying, 'MONTHLY'::character varying])::text[]))),
    CONSTRAINT closing_wizard_wizard_status_check CHECK (((wizard_status)::text = ANY ((ARRAY['IN_PROGRESS'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: closing_wizard_step; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.closing_wizard_step (
    id uuid NOT NULL,
    can_proceed boolean NOT NULL,
    completed boolean NOT NULL,
    step_data text,
    step_description character varying(1000),
    step_number integer NOT NULL,
    step_title character varying(200) NOT NULL,
    wizard_id uuid NOT NULL
);


--
-- Name: collected_inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collected_inventory (
    id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    currency_code character varying(3) NOT NULL,
    denomination_details text,
    huf_value numeric(18,2),
    data_collection_id uuid NOT NULL
);


--
-- Name: collected_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collected_transaction (
    id uuid NOT NULL,
    currency_code character varying(3) NOT NULL,
    customer_name character varying(200),
    foreign_amount numeric(15,2) NOT NULL,
    huf_amount numeric(15,2) NOT NULL,
    original_transaction_id bigint NOT NULL,
    rate numeric(12,4) NOT NULL,
    receipt_number character varying(20),
    transaction_timestamp timestamp(6) without time zone NOT NULL,
    transaction_type character varying(30) NOT NULL,
    data_collection_id uuid NOT NULL,
    CONSTRAINT collected_transaction_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying, 'REVERSAL'::character varying, 'CONVERSION'::character varying, 'TRANSFER_OUT'::character varying, 'TRANSFER_IN'::character varying, 'WESTERN_UNION_SEND'::character varying, 'WESTERN_UNION_RECEIVE'::character varying, 'MONEYGRAM_SEND'::character varying, 'MONEYGRAM_RECEIVE'::character varying, 'VIGNETTE'::character varying, 'PHONE_TOPUP'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: commission_calculation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commission_calculation (
    id uuid NOT NULL,
    approved_at timestamp(6) without time zone,
    approved_by bigint,
    bonus_amount numeric(18,2),
    branch_id uuid NOT NULL,
    calculated_at timestamp(6) without time zone NOT NULL,
    calculation_type character varying(20) NOT NULL,
    commission_amount numeric(18,2),
    commission_rate numeric(10,4),
    created_at timestamp(6) without time zone NOT NULL,
    deductions numeric(18,2),
    net_commission numeric(18,2),
    period character varying(7) NOT NULL,
    status character varying(20) NOT NULL,
    total_transactions integer NOT NULL,
    total_volume_huf numeric(18,2) NOT NULL,
    worker_id bigint NOT NULL,
    CONSTRAINT commission_calculation_calculation_type_check CHECK (((calculation_type)::text = 'MONTHLY'::text)),
    CONSTRAINT commission_calculation_status_check CHECK (((status)::text = ANY ((ARRAY['CALCULATED'::character varying, 'APPROVED'::character varying, 'PAID'::character varying])::text[])))
);


--
-- Name: commission_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commission_rate (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_id bigint,
    entity_id uuid,
    entity_type character varying(50) NOT NULL,
    is_active boolean NOT NULL,
    rate numeric(10,4) NOT NULL,
    updated_at timestamp(6) without time zone,
    valid_from date NOT NULL,
    valid_to date
);


--
-- Name: commission_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.commission_rule (
    id uuid NOT NULL,
    bonus_percent numeric(10,4),
    bonus_threshold numeric(18,2),
    company_id integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    max_volume_huf numeric(18,2),
    min_volume_huf numeric(18,2) NOT NULL,
    rate_percent numeric(10,4) NOT NULL,
    tier integer NOT NULL,
    updated_at timestamp(6) without time zone,
    valid_from date NOT NULL,
    valid_to date
);


--
-- Name: company; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.company (
    id uuid NOT NULL,
    address text,
    code character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying(255),
    is_active boolean,
    name character varying(255) NOT NULL,
    phone character varying(50),
    registration_number character varying(50),
    tax_number character varying(20),
    updated_at timestamp(6) without time zone
);


--
-- Name: competitor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitor (
    id uuid NOT NULL,
    branch_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    is_active boolean NOT NULL,
    name character varying(200) NOT NULL,
    updated_at timestamp(6) without time zone,
    website character varying(500)
);


--
-- Name: competitor_rates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.competitor_rates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    competitor_id uuid NOT NULL,
    currency_id bigint NOT NULL,
    buy_rate numeric(18,6),
    sell_rate numeric(18,6),
    rate_date date NOT NULL,
    source character varying(100),
    created_by bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: contribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contribution (
    id uuid NOT NULL,
    amount numeric(18,2) NOT NULL,
    branch_id uuid NOT NULL,
    calculated_at timestamp(6) without time zone,
    contribution_type character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_id bigint,
    period_end date NOT NULL,
    period_start date NOT NULL,
    status character varying(30) NOT NULL,
    updated_at timestamp(6) without time zone,
    CONSTRAINT contribution_status_check CHECK (((status)::text = ANY ((ARRAY['CALCULATED'::character varying, 'APPROVED'::character varying, 'PAID'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: currency; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency (
    id bigint NOT NULL,
    is_active boolean NOT NULL,
    code character varying(3) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    decimal_places integer NOT NULL,
    default_buy_spread numeric(5,2),
    default_sell_spread numeric(5,2),
    display_order integer,
    flag_icon character varying(255),
    max_transaction_amount numeric(15,2),
    min_transaction_amount numeric(15,2),
    name character varying(100) NOT NULL,
    symbol character varying(10),
    updated_at timestamp(6) without time zone,
    max_deviation_percent numeric(5,2)
);


--
-- Name: COLUMN currency.max_deviation_percent; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.currency.max_deviation_percent IS 'Maximum allowed deviation (%) from official rate. NULL = no limit. MNB regulation.';


--
-- Name: currency_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_group (
    id uuid NOT NULL,
    code character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_ids text,
    description text,
    is_active boolean NOT NULL,
    name character varying(200) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: currency_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_id_seq OWNED BY public.currency.id;


--
-- Name: currency_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_stock (
    id bigint NOT NULL,
    currency_code character varying(3) NOT NULL,
    entity_id character varying(36) NOT NULL,
    entity_type character varying(20) NOT NULL,
    last_updated timestamp(6) without time zone,
    quantity numeric(15,2) NOT NULL,
    weighted_avg_cost numeric(12,4) NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: currency_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_stock_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_stock_id_seq OWNED BY public.currency_stock.id;


--
-- Name: customer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer (
    id bigint NOT NULL,
    active boolean NOT NULL,
    address character varying(500),
    birth_date date,
    birth_name character varying(200),
    birth_place character varying(100),
    city character varying(100),
    company_name character varying(200),
    country character varying(3),
    created_at timestamp(6) without time zone NOT NULL,
    customer_code character varying(50),
    customer_type character varying(20) NOT NULL,
    document_expiry date,
    document_number character varying(50),
    document_type character varying(30),
    email character varying(100),
    id_card_expiry date,
    id_card_number character varying(30),
    is_company boolean,
    is_foreign boolean,
    is_pep boolean,
    is_vip boolean,
    last_transaction_date date,
    mother_name character varying(200),
    name character varying(200) NOT NULL,
    nationality character varying(3),
    notes character varying(1000),
    passport_expiry date,
    passport_number character varying(30),
    phone character varying(30),
    postal_code character varying(10),
    registration_number character varying(50),
    tax_number character varying(20),
    transaction_count integer,
    updated_at timestamp(6) without time zone,
    company_id uuid NOT NULL,
    high_risk_flag boolean DEFAULT false NOT NULL,
    high_risk_reason character varying(500),
    high_risk_set_at timestamp without time zone,
    CONSTRAINT customer_customer_type_check CHECK (((customer_type)::text = ANY ((ARRAY['FULL'::character varying, 'SIMPLIFIED'::character varying])::text[]))),
    CONSTRAINT customer_document_type_check CHECK (((document_type)::text = ANY ((ARRAY['ID_CARD'::character varying, 'PASSPORT'::character varying, 'DRIVING_LICENSE'::character varying, 'RESIDENCE_PERMIT'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customer_id_seq OWNED BY public.customer.id;


--
-- Name: customer_restriction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_restriction (
    id uuid NOT NULL,
    is_active boolean NOT NULL,
    added_at timestamp(6) without time zone NOT NULL,
    added_by bigint NOT NULL,
    customer_id bigint NOT NULL,
    expires_at timestamp(6) without time zone,
    reason text NOT NULL,
    restriction_type character varying(30) NOT NULL
);


--
-- Name: customer_screening_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_screening_log (
    id uuid NOT NULL,
    customer_id bigint NOT NULL,
    details jsonb,
    result character varying(20) NOT NULL,
    screened_at timestamp(6) without time zone NOT NULL,
    screened_by bigint NOT NULL,
    screening_type character varying(30) NOT NULL
);


--
-- Name: daily_balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_balance (
    id bigint NOT NULL,
    actual_stock numeric(18,2),
    balance_date date NOT NULL,
    branch_id uuid NOT NULL,
    closed_at timestamp(6) without time zone,
    closed_by character varying(100),
    closing_balance numeric(18,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    difference numeric(18,2),
    difference_note text,
    is_closed boolean,
    opening_balance numeric(18,2) NOT NULL,
    purchases numeric(18,2) NOT NULL,
    sales numeric(18,2) NOT NULL,
    transfers_in numeric(18,2) NOT NULL,
    transfers_out numeric(18,2) NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: daily_balance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_balance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_balance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_balance_id_seq OWNED BY public.daily_balance.id;


--
-- Name: daily_checklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_checklist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    checklist_date date NOT NULL,
    worker_id bigint NOT NULL,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    completed_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: daily_checklist_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_checklist_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    checklist_id uuid NOT NULL,
    item_number integer NOT NULL,
    item_title character varying(200) NOT NULL,
    item_description character varying(500),
    checked boolean DEFAULT false NOT NULL,
    checked_at timestamp without time zone,
    checked_by_worker_id bigint,
    notes character varying(500)
);


--
-- Name: daily_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_report (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    report_data text,
    report_date date NOT NULL,
    submitted boolean NOT NULL,
    submitted_at timestamp(6) without time zone,
    total_buy_huf numeric(18,2),
    total_fee_huf numeric(18,2),
    total_profit numeric(18,2),
    total_sell_huf numeric(18,2),
    transaction_count integer,
    branch_id uuid NOT NULL,
    submitted_by_id bigint
);


--
-- Name: daily_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_report_id_seq OWNED BY public.daily_report.id;


--
-- Name: daily_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_session (
    id bigint NOT NULL,
    buy_count integer,
    buy_turnover_huf numeric(15,2),
    closed_at timestamp(6) without time zone,
    closing_balance_huf numeric(15,2),
    created_at timestamp(6) without time zone NOT NULL,
    denomination_verified boolean,
    handling_fee_total numeric(15,2),
    nav_uploaded boolean,
    notes character varying(1000),
    opened_at timestamp(6) without time zone,
    opening_balance_huf numeric(15,2),
    qr_code_generated boolean,
    reversal_count integer,
    sell_count integer,
    sell_turnover_huf numeric(15,2),
    session_date date NOT NULL,
    status character varying(20) NOT NULL,
    transaction_count integer,
    updated_at timestamp(6) without time zone,
    branch_id uuid NOT NULL,
    closed_by_worker_id bigint,
    company_id uuid NOT NULL,
    opened_by_worker_id bigint,
    CONSTRAINT daily_session_status_check CHECK (((status)::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSED'::character varying, 'PENDING_CLOSE'::character varying])::text[])))
);


--
-- Name: daily_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.daily_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: daily_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.daily_session_id_seq OWNED BY public.daily_session.id;


--
-- Name: darius_daily_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.darius_daily_report (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    company_id uuid NOT NULL,
    report_date date NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    total_buy_huf numeric(18,2),
    total_sell_huf numeric(18,2),
    transaction_count integer,
    total_handling_fee_huf numeric(18,2),
    branch_count integer,
    payload text,
    payload_format character varying(10),
    payload_hash character varying(64),
    submitted_at timestamp without time zone,
    submitted_by character varying(100),
    ack_reference character varying(200),
    ack_at timestamp without time zone,
    error_message text,
    retry_count integer DEFAULT 0 NOT NULL,
    max_retries integer DEFAULT 3 NOT NULL,
    next_retry_at timestamp without time zone,
    approved_by character varying(100),
    approved_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    notes text
);


--
-- Name: darius_report_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.darius_report_line (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    report_id uuid NOT NULL,
    branch_id uuid NOT NULL,
    branch_code character varying(20),
    currency_code character varying(3) NOT NULL,
    buy_count integer DEFAULT 0,
    buy_currency_amount numeric(18,4) DEFAULT 0,
    buy_huf_amount numeric(18,2) DEFAULT 0,
    sell_count integer DEFAULT 0,
    sell_currency_amount numeric(18,4) DEFAULT 0,
    sell_huf_amount numeric(18,2) DEFAULT 0,
    avg_buy_rate numeric(12,4),
    avg_sell_rate numeric(12,4),
    handling_fee_huf numeric(18,2) DEFAULT 0
);


--
-- Name: data_collection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_collection (
    id uuid NOT NULL,
    collection_date date NOT NULL,
    collection_type character varying(20) NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    error_message character varying(2000),
    started_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    total_buy_huf numeric(18,2),
    total_sell_huf numeric(18,2),
    transaction_count integer,
    updated_at timestamp(6) without time zone,
    branch_id uuid NOT NULL,
    CONSTRAINT data_collection_collection_type_check CHECK (((collection_type)::text = ANY ((ARRAY['DAILY'::character varying, 'HOURLY'::character varying, 'ON_DEMAND'::character varying])::text[]))),
    CONSTRAINT data_collection_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'COLLECTING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying])::text[])))
);


--
-- Name: data_import_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_import_jobs (
    id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    error_log text,
    failed_records integer,
    import_type character varying(30) NOT NULL,
    imported_records integer,
    source_file character varying(500),
    source_type character varying(10) NOT NULL,
    started_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    total_records integer,
    updated_at timestamp(6) without time zone,
    branch_id uuid NOT NULL,
    CONSTRAINT data_import_jobs_import_type_check CHECK (((import_type)::text = ANY ((ARRAY['DAILY_CLOSING'::character varying, 'INVENTORY'::character varying, 'TRANSACTIONS'::character varying, 'RATES'::character varying, 'FULL'::character varying])::text[]))),
    CONSTRAINT data_import_jobs_source_type_check CHECK (((source_type)::text = ANY ((ARRAY['API'::character varying, 'FILE'::character varying, 'FTP'::character varying])::text[]))),
    CONSTRAINT data_import_jobs_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'RUNNING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying])::text[])))
);


--
-- Name: decade_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decade_report (
    id uuid NOT NULL,
    closed_at timestamp(6) without time zone,
    closed_by bigint,
    created_at timestamp(6) without time zone NOT NULL,
    decade integer NOT NULL,
    status character varying(20) NOT NULL,
    total_buy_huf numeric(18,2) NOT NULL,
    total_handling_fee numeric(18,2) NOT NULL,
    total_sell_huf numeric(18,2) NOT NULL,
    transaction_count integer NOT NULL,
    updated_at timestamp(6) without time zone,
    year integer NOT NULL,
    branch_id uuid NOT NULL,
    opening_inventory_value_huf numeric(18,2) DEFAULT 0,
    closing_inventory_value_huf numeric(18,2) DEFAULT 0,
    decade_profit_huf numeric(18,2) DEFAULT 0,
    forint_opening numeric(18,2) DEFAULT 0,
    forint_total_income numeric(18,2) DEFAULT 0,
    forint_total_expense numeric(18,2) DEFAULT 0,
    forint_closing numeric(18,2) DEFAULT 0,
    forint_control_valid boolean DEFAULT false,
    forint_control_diff numeric(18,2) DEFAULT 0,
    first_receipt_number character varying(20),
    last_receipt_number character varying(20),
    card_payment_total numeric(18,2) DEFAULT 0,
    print_control_flag boolean DEFAULT false,
    CONSTRAINT decade_report_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'CLOSED'::character varying])::text[])))
);


--
-- Name: decade_report_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.decade_report_line (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    decade_report_id uuid NOT NULL,
    currency_code character varying(3) NOT NULL,
    opening_balance numeric(18,4) DEFAULT 0 NOT NULL,
    opening_mnb_rate numeric(12,4),
    opening_value_huf numeric(18,2) DEFAULT 0 NOT NULL,
    closing_balance numeric(18,4) DEFAULT 0 NOT NULL,
    closing_mnb_rate numeric(12,4),
    closing_value_huf numeric(18,2) DEFAULT 0 NOT NULL,
    profit_huf numeric(18,2) DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: denomination; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.denomination (
    id bigint NOT NULL,
    active boolean NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    denomination_type character varying(20) NOT NULL,
    face_value numeric(15,2) NOT NULL,
    max_quantity integer,
    min_quantity integer,
    quantity integer NOT NULL,
    updated_at timestamp(6) without time zone,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    currency_id bigint NOT NULL,
    CONSTRAINT denomination_denomination_type_check CHECK (((denomination_type)::text = ANY ((ARRAY['BANKNOTE'::character varying, 'COIN'::character varying])::text[])))
);


--
-- Name: denomination_balance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.denomination_balance (
    id uuid NOT NULL,
    cash_desk_id uuid NOT NULL,
    quantity integer NOT NULL,
    total_value numeric(15,2) NOT NULL,
    updated_at timestamp(6) without time zone,
    denomination_id bigint NOT NULL,
    denomination_category character varying(30) DEFAULT 'EVENING'::character varying
);


--
-- Name: denomination_count; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.denomination_count (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    count_type character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    face_value numeric(15,2) NOT NULL,
    quantity integer NOT NULL,
    session_id uuid NOT NULL,
    worker_id bigint,
    denomination_category character varying(30) DEFAULT 'EVENING'::character varying
);


--
-- Name: denomination_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.denomination_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: denomination_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.denomination_id_seq OWNED BY public.denomination.id;


--
-- Name: dictionary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dictionary (
    id uuid NOT NULL,
    category character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    is_active boolean,
    name character varying(255) NOT NULL,
    name_hu character varying(255),
    sort_order integer,
    updated_at timestamp(6) without time zone
);


--
-- Name: document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document (
    id uuid NOT NULL,
    entity_id uuid,
    entity_type character varying(100),
    file_data oid,
    file_name character varying(255) NOT NULL,
    file_size bigint,
    file_type character varying(100),
    uploaded_at timestamp(6) without time zone NOT NULL,
    uploaded_by_id bigint,
    company_id uuid
);


--
-- Name: email_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_account (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    display_name character varying(200),
    gmail_address character varying(255) NOT NULL,
    is_active boolean NOT NULL,
    last_sync_at timestamp(6) without time zone,
    oauth_access_token text,
    oauth_refresh_token text,
    oauth_token_expiry timestamp(6) without time zone,
    sync_error text,
    updated_at timestamp(6) without time zone,
    branch_id uuid,
    configured_by_worker_id bigint,
    own_company_id uuid,
    vault_territory_id integer,
    worker_id bigint
);


--
-- Name: email_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_cache (
    id uuid NOT NULL,
    cached_at timestamp(6) without time zone NOT NULL,
    gmail_message_id character varying(100) NOT NULL,
    has_attachments boolean NOT NULL,
    is_read boolean NOT NULL,
    is_starred boolean NOT NULL,
    label_ids text,
    received_at timestamp(6) without time zone NOT NULL,
    recipients text,
    sender_address character varying(255),
    snippet character varying(500),
    subject character varying(500),
    thread_id character varying(100),
    email_account_id uuid NOT NULL
);


--
-- Name: employee; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee (
    id bigint NOT NULL,
    is_active boolean NOT NULL,
    birth_country character varying(100),
    birth_date date,
    birth_first_name character varying(100),
    birth_last_name character varying(100),
    birth_place character varying(100),
    certificate_date date,
    citizenship character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(50),
    credit_validity_last_month character varying(20),
    email character varying(200),
    employment_end_date date,
    employment_start_date date,
    employment_type character varying(200),
    family_tax_credit character varying(100),
    feor_code character varying(10),
    first_marriage_credit character varying(100),
    first_name character varying(100) NOT NULL,
    four_plus_children_credit character varying(100),
    has_secondary_education boolean,
    id_card_expiry date,
    id_card_number character varying(30),
    job_title character varying(200),
    last_name character varying(100) NOT NULL,
    marriage_date date,
    mothers_name character varying(150),
    organization_unit character varying(100),
    payment_method character varying(5),
    pension_start_date date,
    pension_type character varying(50),
    personal_tax_credit character varying(100),
    phone character varying(30),
    reduced_work_capacity boolean,
    reduced_work_capacity_type character varying(100),
    salary_amount numeric(38,2),
    salary_type character varying(5),
    serial_number integer,
    social_security_number character varying(20),
    tax_id character varying(20),
    three_children_credit character varying(100),
    two_children_credit character varying(100),
    under_25_youth_credit_amount character varying(100),
    under_25_youth_credit_expiry date,
    under_30_mother_credit_amount character varying(100),
    updated_at timestamp(6) without time zone,
    updated_by character varying(50),
    vocational_qualification character varying(300),
    vocational_school_name character varying(300),
    work_hours_per_day numeric(38,2),
    company_id uuid NOT NULL,
    worker_id bigint,
    CONSTRAINT employee_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['B'::character varying, 'K'::character varying])::text[]))),
    CONSTRAINT employee_salary_type_check CHECK (((salary_type)::text = ANY ((ARRAY['HB'::character varying, 'OB'::character varying])::text[])))
);


--
-- Name: employee_address; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_address (
    id bigint NOT NULL,
    address_type character varying(20) NOT NULL,
    building character varying(30),
    city character varying(100),
    door character varying(20),
    floor character varying(20),
    house_number character varying(20),
    postal_code character varying(10),
    staircase character varying(30),
    street_name character varying(200),
    street_type character varying(50),
    employee_id bigint NOT NULL,
    CONSTRAINT employee_address_address_type_check CHECK (((address_type)::text = ANY ((ARRAY['PERMANENT'::character varying, 'MAILING'::character varying, 'TEMPORARY'::character varying])::text[])))
);


--
-- Name: employee_address_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_address_id_seq OWNED BY public.employee_address.id;


--
-- Name: employee_bank_account; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.employee_bank_account (
    id bigint NOT NULL,
    account_number character varying(50),
    account_type character varying(20) NOT NULL,
    bank_code character varying(10),
    employee_id bigint NOT NULL,
    CONSTRAINT employee_bank_account_account_type_check CHECK (((account_type)::text = ANY ((ARRAY['SALARY'::character varying, 'SZEP_CARD'::character varying])::text[])))
);


--
-- Name: employee_bank_account_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_bank_account_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_bank_account_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_bank_account_id_seq OWNED BY public.employee_bank_account.id;


--
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.employee_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.id;


--
-- Name: error_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.error_logs (
    id character varying(36) NOT NULL,
    app_name character varying(50) NOT NULL,
    browser character varying(300),
    commit_sha character varying(40),
    created_at timestamp(6) with time zone NOT NULL,
    email_sent boolean NOT NULL,
    email_sent_at timestamp(6) with time zone,
    environment character varying(20) NOT NULL,
    error_type character varying(50) NOT NULL,
    fingerprint character varying(32) NOT NULL,
    first_seen_at timestamp(6) with time zone NOT NULL,
    last_seen_at timestamp(6) with time zone NOT NULL,
    message text NOT NULL,
    occurrence_count integer NOT NULL,
    repo_path character varying(100) NOT NULL,
    request_body text,
    request_id character varying(100),
    request_method character varying(10),
    resolved boolean NOT NULL,
    resolved_at timestamp(6) with time zone,
    resolved_commit character varying(40),
    severity character varying(10) NOT NULL,
    stack text,
    url character varying(500),
    user_email character varying(200),
    user_id character varying(100)
);


--
-- Name: evening_closing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evening_closing (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    closing_date date NOT NULL,
    company_id uuid NOT NULL,
    confirmed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    inventory_snapshot jsonb,
    package_data jsonb,
    sent_at timestamp(6) without time zone,
    status character varying(20) NOT NULL,
    total_buy_huf numeric(15,2) NOT NULL,
    total_sell_huf numeric(15,2) NOT NULL,
    transaction_count integer NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: evening_sync_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.evening_sync_log (
    id bigint NOT NULL,
    attempt_count integer NOT NULL,
    branch_id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    error_message text,
    last_attempt_at timestamp(6) without time zone,
    package_checksum character varying(128),
    status character varying(30) NOT NULL,
    sync_date date NOT NULL
);


--
-- Name: evening_sync_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.evening_sync_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: evening_sync_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.evening_sync_log_id_seq OWNED BY public.evening_sync_log.id;


--
-- Name: exchange_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rate (
    id bigint NOT NULL,
    is_active boolean NOT NULL,
    base_buy_rate numeric(12,4) NOT NULL,
    base_sell_rate numeric(12,4) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(50),
    limit1_amount numeric(15,2),
    limit1_buy_rate numeric(12,4),
    limit1_sell_rate numeric(12,4),
    limit2_amount numeric(15,2),
    limit2_buy_rate numeric(12,4),
    limit2_sell_rate numeric(12,4),
    limit3_amount numeric(15,2),
    limit3_buy_rate numeric(12,4),
    limit3_sell_rate numeric(12,4),
    official_rate numeric(12,4),
    valid_date date NOT NULL,
    valid_time time(6) without time zone NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    branch_id uuid,
    company_id uuid NOT NULL,
    currency_id bigint NOT NULL
);


--
-- Name: exchange_rate_display; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rate_display (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_ids text,
    display_name character varying(200) NOT NULL,
    is_active boolean NOT NULL,
    refresh_interval integer NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: exchange_rate_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchange_rate_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchange_rate_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchange_rate_id_seq OWNED BY public.exchange_rate.id;


--
-- Name: exchange_rate_source; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exchange_rate_source (
    id bigint NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    error_count bigint,
    last_error character varying(1000),
    last_error_at timestamp(6) without time zone,
    last_polled_at timestamp(6) without time zone,
    last_success_at timestamp(6) without time zone,
    polling_interval_minutes integer,
    source_name character varying(50) NOT NULL,
    source_url character varying(500),
    success_count bigint,
    updated_at timestamp(6) without time zone
);


--
-- Name: exchange_rate_source_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exchange_rate_source_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exchange_rate_source_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exchange_rate_source_id_seq OWNED BY public.exchange_rate_source.id;


--
-- Name: fee_discount; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fee_discount (
    id uuid NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    discount_type character varying(50),
    discount_value numeric(10,4),
    is_active boolean NOT NULL,
    min_transaction_amount numeric(15,2),
    name character varying(200) NOT NULL,
    updated_at timestamp(6) without time zone,
    valid_from date,
    valid_to date
);


--
-- Name: fee_rate; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fee_rate (
    id uuid NOT NULL,
    branch_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    currency_id bigint,
    fee_type_id uuid NOT NULL,
    fixed_amount numeric(15,2),
    is_active boolean NOT NULL,
    max_amount numeric(15,2),
    min_amount numeric(15,2),
    rate numeric(10,4),
    updated_at timestamp(6) without time zone,
    valid_from date,
    valid_to date
);


--
-- Name: fee_type; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fee_type (
    id uuid NOT NULL,
    calculation_method character varying(50),
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    is_active boolean NOT NULL,
    name character varying(200) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: feor_code; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feor_code (
    id bigint NOT NULL,
    code character varying(10) NOT NULL,
    title character varying(255) NOT NULL
);


--
-- Name: feor_code_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feor_code_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feor_code_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feor_code_id_seq OWNED BY public.feor_code.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: ftp_sync_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ftp_sync_log (
    id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    direction character varying(20) NOT NULL,
    error_message text,
    file_name character varying(255),
    file_size_bytes bigint,
    started_at timestamp(6) without time zone NOT NULL,
    status character varying(20) NOT NULL,
    branch_id uuid NOT NULL,
    CONSTRAINT ftp_sync_log_direction_check CHECK (((direction)::text = ANY ((ARRAY['UPLOAD'::character varying, 'DOWNLOAD'::character varying])::text[]))),
    CONSTRAINT ftp_sync_log_status_check CHECK (((status)::text = ANY ((ARRAY['SUCCESS'::character varying, 'FAILED'::character varying])::text[])))
);


--
-- Name: handling_fee_bracket; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handling_fee_bracket (
    id bigint NOT NULL,
    active boolean NOT NULL,
    bracket_order integer NOT NULL,
    fee_amount numeric(15,0) NOT NULL,
    upper_limit numeric(15,0) NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: handling_fee_bracket_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.handling_fee_bracket_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: handling_fee_bracket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.handling_fee_bracket_id_seq OWNED BY public.handling_fee_bracket.id;


--
-- Name: handling_fee_decade_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handling_fee_decade_report (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    branch_id uuid NOT NULL,
    year integer NOT NULL,
    decade integer NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    opening_balance numeric(18,2) DEFAULT 0 NOT NULL,
    total_buy_fee numeric(18,2) DEFAULT 0 NOT NULL,
    total_sell_fee numeric(18,2) DEFAULT 0 NOT NULL,
    total_card_fee numeric(18,2) DEFAULT 0 NOT NULL,
    total_cash_fee numeric(18,2) DEFAULT 0 NOT NULL,
    closing_balance numeric(18,2) DEFAULT 0 NOT NULL,
    first_sequence_number integer,
    last_sequence_number integer,
    buy_count integer DEFAULT 0 NOT NULL,
    sell_count integer DEFAULT 0 NOT NULL,
    total_count integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    printed boolean DEFAULT false NOT NULL,
    closed_at timestamp without time zone,
    closed_by bigint,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone
);


--
-- Name: handling_fee_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handling_fee_transaction (
    id uuid NOT NULL,
    amount numeric(18,2) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    discount_percent integer NOT NULL,
    discount_reason character varying(255),
    fee_type character varying(20) NOT NULL,
    net_fee numeric(18,2) NOT NULL,
    transaction_id bigint NOT NULL,
    worker_commission_share numeric(18,2) NOT NULL,
    CONSTRAINT handling_fee_transaction_fee_type_check CHECK (((fee_type)::text = ANY ((ARRAY['FIXED'::character varying, 'PERCENT'::character varying, 'TIERED'::character varying])::text[])))
);


--
-- Name: handover_sheet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.handover_sheet (
    id uuid NOT NULL,
    amounts text,
    created_at timestamp(6) without time zone NOT NULL,
    created_by_id bigint,
    from_cash_desk_id uuid NOT NULL,
    notes text,
    sheet_number character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    to_cash_desk_id uuid NOT NULL,
    transfer_date date NOT NULL,
    CONSTRAINT handover_sheet_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'PRINTED'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: hrk_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hrk_transaction (
    id uuid NOT NULL,
    amount numeric(15,2) NOT NULL,
    bank_account_number character varying(50),
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    huf_amount numeric(15,2) NOT NULL,
    note text,
    reference character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    type character varying(20) NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: initial_fee_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initial_fee_config (
    id bigint NOT NULL,
    active boolean NOT NULL,
    daily_custom_fee_limit integer,
    daily_discount_limit integer,
    fee_amount numeric(10,0) NOT NULL,
    fee_name character varying(100) NOT NULL,
    max_fee_amount numeric(10,0),
    min_transaction_amount numeric(15,0),
    company_id uuid NOT NULL
);


--
-- Name: initial_fee_config_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initial_fee_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initial_fee_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initial_fee_config_id_seq OWNED BY public.initial_fee_config.id;


--
-- Name: inventory_movement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_movement (
    id bigint NOT NULL,
    amount numeric(18,4) NOT NULL,
    approved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    huf_value numeric(18,2),
    movement_date date NOT NULL,
    movement_time time(6) without time zone NOT NULL,
    movement_type character varying(30) NOT NULL,
    notes text,
    received_at timestamp(6) without time zone,
    reference_number character varying(30) NOT NULL,
    status character varying(20) NOT NULL,
    approved_by_id bigint,
    currency_id bigint NOT NULL,
    from_branch_id uuid,
    initiated_by_id bigint NOT NULL,
    received_by_id bigint,
    to_branch_id uuid,
    CONSTRAINT inventory_movement_movement_type_check CHECK (((movement_type)::text = ANY ((ARRAY['BANK_WITHDRAW'::character varying, 'BANK_DEPOSIT'::character varying, 'BRANCH_TRANSFER'::character varying, 'CORRECTION'::character varying, 'INITIAL_STOCK'::character varying])::text[]))),
    CONSTRAINT inventory_movement_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'IN_TRANSIT'::character varying, 'RECEIVED'::character varying, 'CANCELLED'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: inventory_movement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_movement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_movement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_movement_id_seq OWNED BY public.inventory_movement.id;


--
-- Name: inventory_regeneration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_regeneration (
    id bigint NOT NULL,
    corrected_count integer NOT NULL,
    discrepancy_count integer NOT NULL,
    regenerated_at timestamp(6) without time zone NOT NULL,
    result_data text,
    branch_id uuid NOT NULL,
    regenerated_by bigint
);


--
-- Name: inventory_regeneration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_regeneration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_regeneration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_regeneration_id_seq OWNED BY public.inventory_regeneration.id;


--
-- Name: inventory_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_summary (
    id bigint NOT NULL,
    bank_deposit_total numeric(18,2),
    bank_withdraw_total numeric(18,2),
    created_at timestamp(6) without time zone NOT NULL,
    current_stock numeric(18,4) NOT NULL,
    daily_buy_total numeric(18,2),
    daily_fee_total numeric(18,2),
    daily_sell_total numeric(18,2),
    last_updated time(6) without time zone,
    summary_date date NOT NULL,
    branch_id uuid NOT NULL,
    currency_id bigint NOT NULL
);


--
-- Name: inventory_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_summary_id_seq OWNED BY public.inventory_summary.id;


--
-- Name: led_display; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.led_display (
    id uuid NOT NULL,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    display_type character varying(30) NOT NULL,
    last_updated timestamp(6) without time zone NOT NULL,
    branch_id uuid NOT NULL,
    CONSTRAINT led_display_display_type_check CHECK (((display_type)::text = ANY ((ARRAY['RATE_BOARD'::character varying, 'SCROLLING_TEXT'::character varying])::text[])))
);


--
-- Name: led_display_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.led_display_config (
    id uuid NOT NULL,
    connection_string character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    display_type character varying(30) NOT NULL,
    displayed_currencies text,
    is_active boolean NOT NULL,
    last_updated_at timestamp(6) without time zone,
    refresh_interval_seconds integer NOT NULL,
    branch_id uuid NOT NULL,
    serial_display_type character varying(30) DEFAULT 'STANDARD'::character varying,
    com_ports character varying(100) DEFAULT 'COM1'::character varying,
    currencies character varying(200) DEFAULT 'EUR,USD,GBP,CHF'::character varying,
    show_bank_card boolean DEFAULT false NOT NULL,
    speed_command boolean DEFAULT true NOT NULL,
    speed integer DEFAULT 5 NOT NULL,
    end_markers character varying(20) DEFAULT '254'::character varying,
    decimal_separator character(1) DEFAULT ','::bpchar,
    custom_text text,
    display_ids character varying(50),
    updated_at timestamp without time zone,
    CONSTRAINT led_display_config_display_type_check CHECK (((display_type)::text = ANY ((ARRAY['SERIAL'::character varying, 'USB'::character varying, 'NETWORK'::character varying])::text[])))
);


--
-- Name: COLUMN led_display_config.serial_display_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.led_display_config.serial_display_type IS 'STANDARD | CENTRAL_EU | EXTENDED | TEXT_ONLY | MIXED | DUAL_SAME | DUAL_DIFF';


--
-- Name: COLUMN led_display_config.com_ports; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.led_display_config.com_ports IS 'Vesszővel elválasztott COM portok, pl. COM1 vagy COM1,COM2';


--
-- Name: COLUMN led_display_config.currencies; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.led_display_config.currencies IS 'Vesszővel elválasztott valuták, pl. EUR,USD,GBP,CHF';


--
-- Name: COLUMN led_display_config.end_markers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.led_display_config.end_markers IS 'Bájt értékek vesszővel, pl. 254 vagy 254,255 (0xFE, 0xFF)';


--
-- Name: license; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.license (
    id uuid NOT NULL,
    activated_at timestamp(6) without time zone,
    company_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    features text,
    is_active boolean NOT NULL,
    license_key character varying(255) NOT NULL,
    max_branches integer NOT NULL,
    max_workers integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    valid_from date NOT NULL,
    valid_to date NOT NULL
);


--
-- Name: material_receipt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_receipt (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    receipt_number character varying(30) NOT NULL,
    receipt_type character varying(1) NOT NULL,
    vault_territory_id integer,
    branch_code character varying(10),
    counterpart_name character varying(200),
    note character varying(500),
    status character varying(20) DEFAULT 'DRAFT'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    finalized_at timestamp without time zone,
    created_by bigint,
    CONSTRAINT material_receipt_receipt_type_check CHECK (((receipt_type)::text = ANY ((ARRAY['B'::character varying, 'K'::character varying])::text[])))
);


--
-- Name: material_receipt_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_receipt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_receipt_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_receipt_id_seq OWNED BY public.material_receipt.id;


--
-- Name: material_receipt_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.material_receipt_line (
    id bigint NOT NULL,
    receipt_id bigint NOT NULL,
    currency_code character varying(3) NOT NULL,
    amount numeric(18,2) NOT NULL,
    exchange_rate numeric(12,4),
    huf_equivalent numeric(18,2)
);


--
-- Name: material_receipt_line_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_receipt_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: material_receipt_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.material_receipt_line_id_seq OWNED BY public.material_receipt_line.id;


--
-- Name: material_receipt_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.material_receipt_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mnb_exchange_rate_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mnb_exchange_rate_cache (
    id bigint NOT NULL,
    currency_code character varying(3) NOT NULL,
    fetched_at timestamp(6) without time zone NOT NULL,
    official_rate numeric(12,4) NOT NULL,
    rate_date date NOT NULL,
    unit integer NOT NULL
);


--
-- Name: mnb_exchange_rate_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mnb_exchange_rate_cache_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mnb_exchange_rate_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mnb_exchange_rate_cache_id_seq OWNED BY public.mnb_exchange_rate_cache.id;


--
-- Name: mnb_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mnb_report (
    id uuid NOT NULL,
    accepted_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    rejection_reason character varying(1000),
    report_date date NOT NULL,
    report_type character varying(20) NOT NULL,
    status character varying(20) NOT NULL,
    submitted_at timestamp(6) without time zone,
    total_buy_huf numeric(18,2),
    total_sell_huf numeric(18,2),
    total_transactions integer,
    updated_at timestamp(6) without time zone,
    xml_content text,
    branch_id uuid NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    last_retry_at timestamp without time zone,
    mnb_reference_number character varying(100),
    submission_error text,
    acknowledged_at timestamp without time zone,
    rejected_at timestamp without time zone,
    rejection_reason_detail text,
    CONSTRAINT mnb_report_report_type_check CHECK (((report_type)::text = ANY ((ARRAY['DAILY'::character varying, 'WEEKLY'::character varying, 'MONTHLY'::character varying, 'QUARTERLY'::character varying, 'YEARLY'::character varying])::text[]))),
    CONSTRAINT mnb_report_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'ACCEPTED'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: COLUMN mnb_report.retry_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.retry_count IS 'Újraküldési kísérletek száma (max 3)';


--
-- Name: COLUMN mnb_report.last_retry_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.last_retry_at IS 'Utolsó újraküldési kísérlet időpontja';


--
-- Name: COLUMN mnb_report.mnb_reference_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.mnb_reference_number IS 'MNB által visszaadott hivatkozási szám';


--
-- Name: COLUMN mnb_report.submission_error; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.submission_error IS 'Utolsó beküldési hiba szövege';


--
-- Name: COLUMN mnb_report.acknowledged_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.acknowledged_at IS 'MNB elfogadás időpontja';


--
-- Name: COLUMN mnb_report.rejected_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.rejected_at IS 'MNB elutasítás időpontja';


--
-- Name: COLUMN mnb_report.rejection_reason_detail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.mnb_report.rejection_reason_detail IS 'MNB elutasítási indoklás (részletes)';


--
-- Name: mnb_report_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mnb_report_line (
    id uuid NOT NULL,
    buy_amount numeric(18,2),
    buy_rate numeric(12,4),
    currency_code character varying(3) NOT NULL,
    sell_amount numeric(18,2),
    sell_rate numeric(12,4),
    transaction_count integer,
    mnb_report_id uuid NOT NULL
);


--
-- Name: monthly_closing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monthly_closing (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    buy_count integer,
    closed_by_id bigint,
    closing_month integer,
    closing_year integer,
    company_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    reversal_count integer,
    sell_count integer,
    status character varying(20),
    total_buy_huf numeric(18,2),
    total_handling_fees numeric(18,2),
    total_profit_huf numeric(18,2),
    total_sell_huf numeric(18,2),
    total_transaction_count integer,
    transaction_count integer,
    year_month character varying(7) NOT NULL
);


--
-- Name: monthly_closing_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monthly_closing_summary (
    id bigint NOT NULL,
    closed_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_breakdown text,
    total_buy_huf numeric(18,2) NOT NULL,
    total_handling_fee numeric(18,2) NOT NULL,
    total_sell_huf numeric(18,2) NOT NULL,
    transaction_count integer NOT NULL,
    year_month character varying(7) NOT NULL,
    branch_id uuid NOT NULL,
    closed_by_worker_id bigint NOT NULL
);


--
-- Name: monthly_closing_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.monthly_closing_summary_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: monthly_closing_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.monthly_closing_summary_id_seq OWNED BY public.monthly_closing_summary.id;


--
-- Name: nav_closing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nav_closing (
    id uuid NOT NULL,
    closed_at timestamp(6) without time zone,
    closing_date date NOT NULL,
    closing_type character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    handling_fee_total numeric(18,2),
    nav_reference_number character varying(100),
    status character varying(20) NOT NULL,
    total_expense numeric(18,2),
    total_revenue numeric(18,2),
    updated_at timestamp(6) without time zone,
    vat_amount numeric(18,2),
    branch_id uuid NOT NULL,
    closed_by bigint,
    CONSTRAINT nav_closing_closing_type_check CHECK (((closing_type)::text = ANY ((ARRAY['DAILY'::character varying, 'MONTHLY'::character varying, 'YEARLY'::character varying])::text[]))),
    CONSTRAINT nav_closing_status_check CHECK (((status)::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSED'::character varying, 'SUBMITTED'::character varying, 'VERIFIED'::character varying])::text[])))
);


--
-- Name: nav_closing_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nav_closing_line (
    id uuid NOT NULL,
    buy_amount numeric(18,2),
    buy_huf numeric(18,2),
    currency_code character varying(3) NOT NULL,
    handling_fee numeric(18,2),
    sell_amount numeric(18,2),
    sell_huf numeric(18,2),
    transaction_count integer,
    nav_closing_id uuid NOT NULL
);


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_read boolean,
    message text NOT NULL,
    title character varying(200) NOT NULL,
    type character varying(30) NOT NULL,
    user_id character varying(50),
    entity_type character varying(100),
    entity_id character varying(100),
    notification_type character varying(100)
);


--
-- Name: organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization (
    id uuid NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    is_active boolean NOT NULL,
    name character varying(200) NOT NULL,
    organization_type_did bigint,
    parent_id uuid,
    updated_at timestamp(6) without time zone
);


--
-- Name: organizational_system_parameter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizational_system_parameter (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_id bigint,
    is_active boolean NOT NULL,
    organization_id uuid NOT NULL,
    parameter_key character varying(100) NOT NULL,
    parameter_value text NOT NULL,
    updated_at timestamp(6) without time zone,
    valid_from date NOT NULL,
    valid_to date
);


--
-- Name: own_company; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.own_company (
    id uuid NOT NULL,
    address character varying(500),
    bank_account_number character varying(50),
    created_at timestamp(6) without time zone NOT NULL,
    email character varying(100),
    iban character varying(50),
    is_active boolean NOT NULL,
    license_number character varying(100),
    name character varying(200) NOT NULL,
    phone character varying(50),
    registration_number character varying(50),
    swift character varying(20),
    tax_number character varying(50),
    updated_at timestamp(6) without time zone
);


--
-- Name: packaging_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.packaging_record (
    id uuid NOT NULL,
    bundle_count integer NOT NULL,
    bundle_size integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    denomination integer NOT NULL,
    notes character varying(500),
    packaging_date date NOT NULL,
    branch_id uuid NOT NULL
);


--
-- Name: permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permission (
    id uuid NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    is_active boolean,
    is_system_permission boolean,
    module character varying(50) NOT NULL,
    name character varying(100) NOT NULL
);


--
-- Name: police_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.police_request (
    id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    customer_name character varying(200),
    date_range_from date,
    date_range_to date,
    document_number character varying(100),
    request_date date NOT NULL,
    request_number character varying(100) NOT NULL,
    requested_by character varying(200) NOT NULL,
    response_data text,
    status character varying(20) NOT NULL,
    updated_at timestamp(6) without time zone,
    created_by bigint,
    CONSTRAINT police_request_status_check CHECK (((status)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PROCESSING'::character varying, 'COMPLETED'::character varying, 'REJECTED'::character varying])::text[])))
);


--
-- Name: pos_terminal; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pos_terminal (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_active boolean NOT NULL,
    last_transaction_at timestamp(6) without time zone,
    terminal_id character varying(50) NOT NULL,
    terminal_name character varying(200),
    terminal_type character varying(30),
    updated_at timestamp(6) without time zone,
    ip_address character varying(50),
    port integer
);


--
-- Name: COLUMN pos_terminal.ip_address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_terminal.ip_address IS 'Terminál IP cím (Legacy: HARDWARE.POSHOST)';


--
-- Name: COLUMN pos_terminal.port; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pos_terminal.port IS 'Terminál port (Legacy: HARDWARE.POSPORT)';


--
-- Name: print_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.print_template (
    id uuid NOT NULL,
    company_id integer,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    is_default boolean NOT NULL,
    name character varying(200) NOT NULL,
    template_type character varying(30) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT print_template_template_type_check CHECK (((template_type)::text = ANY ((ARRAY['RECEIPT'::character varying, 'REPORT'::character varying, 'LABEL'::character varying, 'CLOSING'::character varying])::text[])))
);


--
-- Name: profit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profit_log (
    id bigint NOT NULL,
    acquisition_cost numeric(12,4) NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp(6) without time zone,
    currency_code character varying(3) NOT NULL,
    quantity numeric(15,2) NOT NULL,
    realized_profit numeric(15,2) NOT NULL,
    sale_price numeric(12,4) NOT NULL,
    transaction_id bigint,
    transaction_type character varying(10) NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: profit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.profit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: profit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.profit_log_id_seq OWNED BY public.profit_log.id;


--
-- Name: prohibited_company; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prohibited_company (
    id uuid NOT NULL,
    company_name character varying(300) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_active boolean NOT NULL,
    list_source character varying(200),
    list_type character varying(50),
    reason text,
    registration_number character varying(50),
    tax_number character varying(50),
    updated_at timestamp(6) without time zone
);


--
-- Name: prohibited_person; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prohibited_person (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    date_of_birth date,
    document_number character varying(50),
    full_name character varying(300) NOT NULL,
    identity_number character varying(50),
    is_active boolean NOT NULL,
    list_source character varying(200),
    list_type character varying(50),
    nationality character varying(100),
    passport_number character varying(50),
    reason text,
    updated_at timestamp(6) without time zone
);


--
-- Name: rate_approval; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_approval (
    id uuid NOT NULL,
    approved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    new_buy_rate numeric(12,4) NOT NULL,
    new_sell_rate numeric(12,4) NOT NULL,
    old_buy_rate numeric(12,4),
    old_sell_rate numeric(12,4),
    reason character varying(500),
    requested_at timestamp(6) without time zone NOT NULL,
    status character varying(20) NOT NULL,
    updated_at timestamp(6) without time zone,
    approved_by bigint,
    branch_id uuid NOT NULL,
    requested_by bigint,
    CONSTRAINT rate_approval_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'APPLIED'::character varying])::text[])))
);


--
-- Name: rate_category; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_category (
    id uuid NOT NULL,
    buy_rate numeric(18,6) NOT NULL,
    category character varying(20) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    max_amount numeric(18,2),
    min_amount numeric(18,2),
    sell_rate numeric(18,6) NOT NULL,
    updated_at timestamp(6) without time zone,
    valid_from timestamp(6) without time zone NOT NULL,
    valid_to timestamp(6) without time zone,
    branch_id uuid NOT NULL,
    CONSTRAINT rate_category_category_check CHECK (((category)::text = ANY ((ARRAY['STANDARD'::character varying, 'SMALL'::character varying, 'LARGE'::character varying])::text[])))
);


--
-- Name: rate_discount; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_discount (
    id uuid NOT NULL,
    active boolean,
    buy_discount_percent numeric(8,4),
    level integer NOT NULL,
    name character varying(50) NOT NULL,
    sell_discount_percent numeric(8,4),
    workgroup_id uuid NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: rate_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_history (
    id bigint NOT NULL,
    approved_by bigint,
    branch_id uuid,
    buy_rate numeric(18,6) NOT NULL,
    category character varying(20) NOT NULL,
    company_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    effective_from timestamp(6) without time zone NOT NULL,
    effective_to timestamp(6) without time zone,
    mnb_rate numeric(18,6),
    sell_rate numeric(18,6) NOT NULL,
    set_by bigint,
    spread numeric(10,4),
    CONSTRAINT rate_history_category_check CHECK (((category)::text = ANY ((ARRAY['STANDARD'::character varying, 'SMALL'::character varying, 'LARGE'::character varying])::text[])))
);


--
-- Name: rate_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rate_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rate_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rate_history_id_seq OWNED BY public.rate_history.id;


--
-- Name: rate_publication; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_publication (
    id uuid NOT NULL,
    affected_branches integer,
    notes text,
    published_at timestamp(6) without time zone,
    published_by bigint NOT NULL,
    template_id uuid,
    workgroup_id uuid NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: rate_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_template (
    id uuid NOT NULL,
    approved_at timestamp(6) without time zone,
    approved_by bigint,
    base_buy_rate numeric(18,6) NOT NULL,
    base_sell_rate numeric(18,6) NOT NULL,
    buy_spread numeric(18,6),
    created_at timestamp(6) without time zone,
    created_by bigint,
    currency_id bigint NOT NULL,
    published_at timestamp(6) without time zone,
    rounding_rule integer,
    sell_spread numeric(18,6),
    status character varying(255),
    workgroup_id uuid NOT NULL,
    company_id uuid NOT NULL,
    official_rate numeric(18,6),
    limit1_amount numeric(15,2),
    limit1_buy_rate numeric(18,6),
    limit1_sell_rate numeric(18,6),
    limit2_amount numeric(15,2),
    limit2_buy_rate numeric(18,6),
    limit2_sell_rate numeric(18,6),
    limit3_amount numeric(15,2),
    limit3_buy_rate numeric(18,6),
    limit3_sell_rate numeric(18,6),
    CONSTRAINT rate_template_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'APPROVED'::character varying, 'PUBLISHED'::character varying, 'REVOKED'::character varying])::text[])))
);


--
-- Name: rate_workgroup; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_workgroup (
    id uuid NOT NULL,
    active boolean,
    code character varying(20) NOT NULL,
    created_at timestamp(6) without time zone,
    legacy_group_number integer,
    name character varying(100) NOT NULL,
    company_id uuid NOT NULL,
    limit1_boundary numeric(15,2) DEFAULT 50000,
    limit2_boundary numeric(15,2) DEFAULT 300000,
    limit3_boundary numeric(15,2) DEFAULT 1000000
);


--
-- Name: rate_workgroup_branch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rate_workgroup_branch (
    workgroup_id uuid NOT NULL,
    branch_id uuid NOT NULL
);


--
-- Name: receipt; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receipt (
    id uuid NOT NULL,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    is_printed boolean NOT NULL,
    issue_date date NOT NULL,
    nav_receipt_number character varying(100),
    printed_at timestamp(6) without time zone,
    receipt_number character varying(50) NOT NULL,
    receipt_type character varying(50) NOT NULL,
    transaction_id uuid
);


--
-- Name: receipt_sequence; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.receipt_sequence (
    id bigint NOT NULL,
    branch_id uuid NOT NULL,
    last_buy_receipt bigint NOT NULL,
    last_conversion_receipt bigint NOT NULL,
    last_forint_transfer_in_receipt bigint NOT NULL,
    last_forint_transfer_out_receipt bigint NOT NULL,
    last_sell_receipt bigint NOT NULL,
    last_transfer_in_receipt bigint NOT NULL,
    last_transfer_out_receipt bigint NOT NULL
);


--
-- Name: receipt_sequence_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.receipt_sequence_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: receipt_sequence_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.receipt_sequence_id_seq OWNED BY public.receipt_sequence.id;


--
-- Name: reservation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservation (
    id bigint NOT NULL,
    cancellation_reason character varying(500),
    cancellation_receipt_number character varying(50),
    cancelled_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(3) NOT NULL,
    deposit_amount numeric(15,2) NOT NULL,
    exchange_rate numeric(12,4) NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    fulfilled_at timestamp(6) without time zone,
    notes character varying(1000),
    receipt_number character varying(50),
    refund_amount numeric(15,2),
    reserved_amount numeric(15,2) NOT NULL,
    status character varying(30) NOT NULL,
    supervisor_approval boolean,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    customer_id bigint NOT NULL,
    supervisor_worker_id bigint,
    worker_id bigint NOT NULL,
    CONSTRAINT reservation_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'FULFILLED'::character varying, 'CANCELLED_BY_CUSTOMER'::character varying, 'CANCELLED_BY_COMPANY'::character varying])::text[])))
);


--
-- Name: reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reservation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reservation_id_seq OWNED BY public.reservation.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    id uuid NOT NULL,
    code character varying(30) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    hierarchy_level integer,
    is_active boolean,
    is_system_role boolean,
    name character varying(100) NOT NULL,
    role_type character varying(30)
);


--
-- Name: role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permission (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL
);


--
-- Name: rounding_rule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rounding_rule (
    id bigint NOT NULL,
    currency_code character varying(3) NOT NULL,
    large_rounding character varying(10) NOT NULL,
    large_threshold numeric(15,2) NOT NULL,
    precision_value numeric(10,4) NOT NULL,
    small_rounding character varying(10) NOT NULL,
    small_threshold numeric(15,2) NOT NULL
);


--
-- Name: rounding_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rounding_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rounding_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rounding_rule_id_seq OWNED BY public.rounding_rule.id;


--
-- Name: sanction_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sanction_entries (
    id uuid NOT NULL,
    active boolean NOT NULL,
    added_date date,
    aliases text,
    created_at timestamp(6) without time zone NOT NULL,
    date_of_birth character varying(50),
    document_number character varying(100),
    full_name character varying(500) NOT NULL,
    last_updated date,
    list_reference character varying(500),
    list_type character varying(20) NOT NULL,
    nationality character varying(100),
    updated_at timestamp(6) without time zone
);


--
-- Name: sanction_screening_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sanction_screening_log (
    id uuid NOT NULL,
    branch_code character varying(20),
    created_at timestamp(6) without time zone NOT NULL,
    match_count integer NOT NULL,
    match_details text,
    result character varying(20) NOT NULL,
    screened_date_of_birth character varying(50),
    screened_document_number character varying(100),
    screened_name character varying(500) NOT NULL,
    supervisor_approved boolean,
    supervisor_name character varying(200),
    worker_id character varying(50),
    worker_name character varying(200)
);


--
-- Name: scanned_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scanned_document (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    customer_id uuid,
    deleted_at timestamp(6) without time zone,
    document_type character varying(30) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_size_bytes bigint,
    is_deleted boolean NOT NULL,
    mime_type character varying(100),
    notes character varying(500),
    scanned_at timestamp(6) without time zone NOT NULL,
    scanned_by bigint,
    storage_path character varying(500),
    transaction_id uuid,
    CONSTRAINT scanned_document_document_type_check CHECK (((document_type)::text = ANY ((ARRAY['ID_CARD'::character varying, 'PASSPORT'::character varying, 'DRIVERS_LICENSE'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: scheduled_task; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduled_task (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    cron_expression character varying(50) NOT NULL,
    is_active boolean NOT NULL,
    last_result character varying(20),
    last_run_at timestamp(6) without time zone,
    next_run_at timestamp(6) without time zone,
    parameters jsonb,
    task_name character varying(100) NOT NULL,
    task_type character varying(30) NOT NULL,
    updated_at timestamp(6) without time zone,
    CONSTRAINT scheduled_task_last_result_check CHECK (((last_result)::text = ANY ((ARRAY['SUCCESS'::character varying, 'FAILURE'::character varying, 'SKIPPED'::character varying])::text[]))),
    CONSTRAINT scheduled_task_task_type_check CHECK (((task_type)::text = ANY ((ARRAY['RATE_SYNC'::character varying, 'BACKUP'::character varying, 'REPORT'::character varying, 'CLOSING_REMINDER'::character varying, 'HEALTH_CHECK'::character varying])::text[])))
);


--
-- Name: seal_number; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seal_number (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    note character varying(255),
    seal_number character varying(30) NOT NULL,
    seal_type character varying(20) NOT NULL,
    session_id uuid,
    used_at timestamp(6) without time zone,
    worker_id bigint,
    CONSTRAINT seal_number_seal_type_check CHECK (((seal_type)::text = ANY ((ARRAY['OPEN'::character varying, 'CLOSE'::character varying, 'TRANSFER'::character varying])::text[])))
);


--
-- Name: seal_tracking; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seal_tracking (
    id bigint NOT NULL,
    version bigint DEFAULT 0 NOT NULL,
    company_id uuid NOT NULL,
    transfer_type character varying(20) NOT NULL,
    transfer_id bigint NOT NULL,
    seal_number character varying(50) NOT NULL,
    sealed_at timestamp without time zone NOT NULL,
    sealed_by bigint NOT NULL,
    opened_at timestamp without time zone,
    opened_by bigint,
    transit_status character varying(20) DEFAULT 'SEALED'::character varying NOT NULL,
    notes text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    CONSTRAINT seal_tracking_transit_status_check CHECK (((transit_status)::text = ANY ((ARRAY['SEALED'::character varying, 'IN_TRANSIT'::character varying, 'ARRIVED'::character varying, 'OPENED'::character varying])::text[])))
);


--
-- Name: seal_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seal_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seal_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seal_tracking_id_seq OWNED BY public.seal_tracking.id;


--
-- Name: shipment_request; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipment_request (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    delivery_date date,
    from_branch_id uuid NOT NULL,
    notes text,
    request_date date NOT NULL,
    request_number character varying(50) NOT NULL,
    requested_by_id bigint NOT NULL,
    status character varying(20) NOT NULL,
    to_branch_id uuid NOT NULL,
    CONSTRAINT shipment_request_status_check CHECK (((status)::text = ANY ((ARRAY['DRAFT'::character varying, 'SUBMITTED'::character varying, 'APPROVED'::character varying, 'IN_TRANSIT'::character varying, 'DELIVERED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: shipment_request_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shipment_request_item (
    id uuid NOT NULL,
    approved_amount numeric(15,2),
    currency_id bigint NOT NULL,
    delivered_amount numeric(15,2),
    requested_amount numeric(15,2) NOT NULL,
    shipment_request_id uuid NOT NULL
);


--
-- Name: stamp_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stamp_assignment (
    id uuid NOT NULL,
    assigned_at timestamp(6) without time zone NOT NULL,
    assigned_by character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    serial_number character varying(20) NOT NULL,
    transaction_id bigint,
    stamp_batch_id uuid NOT NULL
);


--
-- Name: stamp_batch; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stamp_batch (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    note character varying(500),
    received_at timestamp(6) without time zone NOT NULL,
    received_by character varying(100),
    serial_end integer NOT NULL,
    serial_prefix character varying(10) NOT NULL,
    serial_start integer NOT NULL
);


--
-- Name: stock_correction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stock_correction (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    entity_type character varying(20) NOT NULL,
    entity_id character varying(36) NOT NULL,
    currency_code character varying(3) NOT NULL,
    old_quantity numeric(18,2) NOT NULL,
    new_quantity numeric(18,2) NOT NULL,
    difference numeric(18,2) NOT NULL,
    reason character varying(500) NOT NULL,
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    approved_at timestamp without time zone,
    created_by bigint,
    approved_by bigint
);


--
-- Name: stock_correction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stock_correction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stock_correction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stock_correction_id_seq OWNED BY public.stock_correction.id;


--
-- Name: storno_approval; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.storno_approval (
    id uuid NOT NULL,
    approved_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    daily_storno_count integer NOT NULL,
    rejection_reason character varying(500),
    request_reason character varying(500) NOT NULL,
    approval_status_did uuid,
    approved_by_worker_id bigint,
    branch_id uuid NOT NULL,
    transaction_id bigint NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: sync_inbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_inbox (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    idempotency_key character varying(120) NOT NULL,
    source_node_id character varying(100) NOT NULL,
    event_type character varying(100) NOT NULL,
    payload_hash character varying(128) NOT NULL,
    status character varying(20) DEFAULT 'RECEIVED'::character varying NOT NULL,
    received_at timestamp without time zone DEFAULT now() NOT NULL,
    processed_at timestamp without time zone,
    CONSTRAINT chk_sync_inbox_status CHECK (((status)::text = ANY ((ARRAY['RECEIVED'::character varying, 'PROCESSED'::character varying, 'FAILED'::character varying, 'DUPLICATE'::character varying])::text[])))
);


--
-- Name: sync_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_log (
    id uuid NOT NULL,
    completed_at timestamp(6) without time zone,
    direction character varying(10) NOT NULL,
    error_message text,
    record_count integer,
    started_at timestamp(6) without time zone NOT NULL,
    status character varying(20) NOT NULL,
    sync_type character varying(20) NOT NULL,
    branch_id uuid NOT NULL,
    CONSTRAINT sync_log_direction_check CHECK (((direction)::text = ANY ((ARRAY['UP'::character varying, 'DOWN'::character varying])::text[]))),
    CONSTRAINT sync_log_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'RUNNING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying])::text[]))),
    CONSTRAINT sync_log_sync_type_check CHECK (((sync_type)::text = ANY ((ARRAY['RATES'::character varying, 'TRANSACTIONS'::character varying, 'INVENTORY'::character varying, 'CLOSING'::character varying, 'FULL'::character varying])::text[])))
);


--
-- Name: sync_outbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_outbox (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    aggregate_type character varying(100) NOT NULL,
    aggregate_id character varying(100) NOT NULL,
    event_type character varying(100) NOT NULL,
    idempotency_key character varying(120) NOT NULL,
    payload jsonb NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    next_retry_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    sent_at timestamp without time zone,
    CONSTRAINT chk_sync_outbox_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'SENT'::character varying, 'FAILED'::character varying, 'DEAD_LETTER'::character varying])::text[])))
);


--
-- Name: system_parameter; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_parameter (
    id uuid NOT NULL,
    category character varying(50) NOT NULL,
    description text,
    is_active boolean,
    parameter_key character varying(100) NOT NULL,
    parameter_type character varying(30) NOT NULL,
    parameter_value text NOT NULL,
    updated_at timestamp(6) without time zone,
    updated_by character varying(100)
);


--
-- Name: token_blacklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_blacklist (
    id bigint NOT NULL,
    token_id character varying(64) NOT NULL,
    worker_id bigint NOT NULL,
    blacklisted_at timestamp without time zone DEFAULT now() NOT NULL,
    reason character varying(50) DEFAULT 'LOGOUT'::character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: TABLE token_blacklist; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.token_blacklist IS 'Visszavont JWT tokenek nyilvántartása — kijelentkezés vagy kényszerített érvénytelenítés';


--
-- Name: token_blacklist_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.token_blacklist_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: token_blacklist_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.token_blacklist_id_seq OWNED BY public.token_blacklist.id;


--
-- Name: trade; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.trade (
    id uuid NOT NULL,
    accepted_at timestamp(6) without time zone,
    accepted_by bigint,
    amount numeric(18,4) NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    currency_code character varying(10) NOT NULL,
    notes text,
    proposed_at timestamp(6) without time zone NOT NULL,
    proposed_by bigint NOT NULL,
    rate numeric(18,6) NOT NULL,
    status character varying(20) NOT NULL,
    from_branch_id uuid NOT NULL,
    to_branch_id uuid NOT NULL,
    CONSTRAINT trade_status_check CHECK (((status)::text = ANY ((ARRAY['PROPOSED'::character varying, 'ACCEPTED'::character varying, 'REJECTED'::character varying, 'COMPLETED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction (
    id bigint NOT NULL,
    aml_annual_limit_reached boolean,
    aml_suspicious boolean,
    approved_by character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    currency_amount numeric(15,2) NOT NULL,
    customer_address character varying(500),
    customer_document_number character varying(50),
    customer_id character varying(50),
    customer_name character varying(200),
    customer_nationality character varying(3),
    discount_amount numeric(15,2),
    discount_percent numeric(5,2),
    discount_type_code integer,
    exchange_rate numeric(12,4) NOT NULL,
    handling_fee numeric(15,2),
    handling_fee_type character varying(20),
    huf_amount numeric(15,2) NOT NULL,
    initial_fee numeric(10,0),
    line_count integer,
    mtcn character varying(50),
    multi_line boolean,
    notes character varying(1000),
    payment_method character varying(20),
    pos_authorization_code character varying(50),
    pos_reference_number character varying(100),
    pos_terminal_id character varying(50),
    printed boolean,
    receipt_number character varying(20) NOT NULL,
    reference_number character varying(100),
    reversal_reason character varying(500),
    rounding_amount numeric(15,2),
    status character varying(20) NOT NULL,
    transaction_date date NOT NULL,
    transaction_time time(6) without time zone NOT NULL,
    transaction_type character varying(30) NOT NULL,
    version bigint,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    currency_id bigint NOT NULL,
    original_transaction_id bigint,
    worker_id bigint NOT NULL,
    linked_receipt_number character varying(20),
    partial_refund_amount numeric(18,4),
    CONSTRAINT transaction_handling_fee_type_check CHECK (((handling_fee_type)::text = ANY ((ARRAY['NONE'::character varying, 'PER_MILLE'::character varying, 'BRACKET'::character varying])::text[]))),
    CONSTRAINT transaction_payment_method_check CHECK (((payment_method)::text = ANY ((ARRAY['CASH'::character varying, 'CARD'::character varying])::text[]))),
    CONSTRAINT transaction_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'COMPLETED'::character varying, 'REVERSED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying, 'ARCHIVED'::character varying])::text[]))),
    CONSTRAINT transaction_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying, 'REVERSAL'::character varying, 'CONVERSION'::character varying, 'TRANSFER_OUT'::character varying, 'TRANSFER_IN'::character varying, 'WESTERN_UNION_SEND'::character varying, 'WESTERN_UNION_RECEIVE'::character varying, 'MONEYGRAM_SEND'::character varying, 'MONEYGRAM_RECEIVE'::character varying, 'VIGNETTE'::character varying, 'PHONE_TOPUP'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: COLUMN transaction.linked_receipt_number; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.transaction.linked_receipt_number IS 'Konverziós bizonylat pár: a másik bizonylat száma (vétel↔eladás)';


--
-- Name: transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_id_seq OWNED BY public.transaction.id;


--
-- Name: transaction_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_line (
    id bigint NOT NULL,
    applied_rate numeric(12,4) NOT NULL,
    banknote_count numeric(15,2) NOT NULL,
    discount_type integer,
    huf_value numeric(15,0) NOT NULL,
    line_discount numeric(15,0),
    line_number integer NOT NULL,
    original_rate numeric(12,4),
    settlement_rate numeric(12,4),
    currency_id bigint NOT NULL,
    transaction_id bigint NOT NULL
);


--
-- Name: transaction_line_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_line_id_seq OWNED BY public.transaction_line.id;


--
-- Name: transfer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer (
    id bigint NOT NULL,
    amount numeric(18,4) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    difference numeric(18,4),
    handover_printed boolean,
    huf_value numeric(18,2),
    notes text,
    receipt_printed boolean,
    received_amount numeric(18,4),
    received_date date,
    received_time time(6) without time zone,
    status character varying(20) NOT NULL,
    transfer_date date NOT NULL,
    transfer_number character varying(30) NOT NULL,
    transfer_time time(6) without time zone NOT NULL,
    transfer_type character varying(20) NOT NULL,
    version bigint,
    currency_id bigint NOT NULL,
    from_branch_id uuid NOT NULL,
    from_worker_id bigint NOT NULL,
    to_branch_id uuid NOT NULL,
    to_worker_id bigint,
    direction character varying(2) DEFAULT 'UF'::character varying,
    CONSTRAINT transfer_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'IN_TRANSIT'::character varying, 'RECEIVED'::character varying, 'COMPLETED'::character varying, 'REJECTED'::character varying, 'CANCELLED'::character varying])::text[]))),
    CONSTRAINT transfer_transfer_type_check CHECK (((transfer_type)::text = ANY ((ARRAY['CURRENCY'::character varying, 'CASH'::character varying, 'HANDLING_FEE'::character varying, 'VAULT_DEPOSIT'::character varying, 'VAULT_WITHDRAW'::character varying, 'CORRECTION'::character varying, 'OTHER'::character varying])::text[])))
);


--
-- Name: COLUMN transfer.direction; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.transfer.direction IS 'Átadás iránya: F=Feladó, U=Vevő, UF=Mindkettő, FF=Korrekció';


--
-- Name: transfer_document; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transfer_document (
    id bigint NOT NULL,
    confirmed_at timestamp(6) without time zone,
    courier_pin_hash character varying(128),
    created_at timestamp(6) without time zone,
    currency_code character varying(3) NOT NULL,
    delivered_at timestamp(6) without time zone,
    destination_id character varying(36),
    destination_type character varying(20) NOT NULL,
    document_number character varying(30) NOT NULL,
    notes text,
    picked_up_at timestamp(6) without time zone,
    quantity numeric(15,2) NOT NULL,
    source_id character varying(36),
    source_type character varying(20) NOT NULL,
    status character varying(20) NOT NULL,
    wac_at_transfer numeric(12,4),
    company_id uuid NOT NULL,
    courier_id bigint,
    receiver_id bigint,
    sender_id bigint NOT NULL,
    CONSTRAINT transfer_document_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'PICKED_UP'::character varying, 'DELIVERED'::character varying, 'CONFIRMED'::character varying])::text[])))
);


--
-- Name: transfer_document_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transfer_document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transfer_document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transfer_document_id_seq OWNED BY public.transfer_document.id;


--
-- Name: transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transfer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transfer_id_seq OWNED BY public.transfer.id;


--
-- Name: translation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translation (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    language_code character varying(5) NOT NULL,
    message_key character varying(200) NOT NULL,
    message_value text NOT NULL,
    module character varying(30) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: translation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.translation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.translation_id_seq OWNED BY public.translation.id;


--
-- Name: vault_bank_transaction; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_bank_transaction (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    vault_territory_id integer,
    transaction_type character varying(10) NOT NULL,
    currency_code character varying(3) NOT NULL,
    amount numeric(18,2) NOT NULL,
    exchange_rate numeric(12,4) NOT NULL,
    huf_amount numeric(18,2) NOT NULL,
    bank_name character varying(100),
    bank_reference character varying(100),
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    note character varying(500),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    created_by bigint,
    approved_by bigint,
    CONSTRAINT vault_bank_transaction_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['BUY'::character varying, 'SELL'::character varying])::text[])))
);


--
-- Name: vault_bank_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_bank_transaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_bank_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_bank_transaction_id_seq OWNED BY public.vault_bank_transaction.id;


--
-- Name: vault_collection; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_collection (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    source_branch_code character varying(10) NOT NULL,
    source_branch_name character varying(100),
    currency_code character varying(3) NOT NULL,
    amount numeric(18,2) NOT NULL,
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    note character varying(500),
    requested_by bigint
);


--
-- Name: vault_collection_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_collection_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_collection_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_collection_id_seq OWNED BY public.vault_collection.id;


--
-- Name: vault_distribution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_distribution (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    note character varying(500),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    created_by bigint
);


--
-- Name: vault_distribution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_distribution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_distribution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_distribution_id_seq OWNED BY public.vault_distribution.id;


--
-- Name: vault_distribution_line; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_distribution_line (
    id bigint NOT NULL,
    distribution_id bigint NOT NULL,
    target_branch_code character varying(10) NOT NULL,
    target_branch_name character varying(100),
    currency_code character varying(3) NOT NULL,
    amount numeric(18,2) NOT NULL
);


--
-- Name: vault_distribution_line_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_distribution_line_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_distribution_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_distribution_line_id_seq OWNED BY public.vault_distribution_line.id;


--
-- Name: vault_territory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_territory (
    id integer NOT NULL,
    active boolean,
    base_capital numeric(15,2) NOT NULL,
    base_capital_approved_at date,
    name character varying(100) NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: vault_territory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_territory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_territory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_territory_id_seq OWNED BY public.vault_territory.id;


--
-- Name: vault_transfer; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vault_transfer (
    id bigint NOT NULL,
    company_id uuid NOT NULL,
    transfer_number character varying(30) NOT NULL,
    source_vault_id integer,
    target_vault_id integer,
    source_branch_code character varying(10),
    target_branch_code character varying(10),
    currency_code character varying(3) NOT NULL,
    amount numeric(18,2) NOT NULL,
    wac_at_transfer numeric(12,4),
    status character varying(20) DEFAULT 'REQUESTED'::character varying NOT NULL,
    requires_supervisor boolean DEFAULT false NOT NULL,
    supervisor_approved_by bigint,
    supervisor_approved_at timestamp without time zone,
    note character varying(500),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    completed_at timestamp without time zone,
    created_by bigint,
    received_by bigint,
    received_at timestamp without time zone,
    CONSTRAINT chk_vault_transfer_direction CHECK ((((source_vault_id IS NOT NULL) OR (source_branch_code IS NOT NULL)) AND ((target_vault_id IS NOT NULL) OR (target_branch_code IS NOT NULL))))
);


--
-- Name: vault_transfer_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_transfer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vault_transfer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vault_transfer_id_seq OWNED BY public.vault_transfer.id;


--
-- Name: vault_transfer_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vault_transfer_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker (
    id bigint NOT NULL,
    is_active boolean NOT NULL,
    code character varying(10) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    created_by character varying(50),
    email character varying(100),
    last_login_at timestamp(6) without time zone,
    name character varying(100) NOT NULL,
    otp_enabled boolean,
    otp_user_id character varying(50),
    password_changed_at timestamp(6) without time zone,
    password_hash character varying(255) NOT NULL,
    phone character varying(20),
    role character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone,
    updated_by character varying(50),
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    CONSTRAINT worker_role_check CHECK (((role)::text = ANY ((ARRAY['CASHIER'::character varying, 'SUPERVISOR'::character varying, 'MANAGER'::character varying, 'ADMIN'::character varying])::text[])))
);


--
-- Name: worker_attendance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_attendance (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    ip_address character varying(50),
    login_at timestamp(6) without time zone NOT NULL,
    logout_at timestamp(6) without time zone,
    session_token character varying(100),
    user_agent character varying(500),
    worker_id bigint NOT NULL
);


--
-- Name: worker_break; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_break (
    id uuid NOT NULL,
    approved_by character varying(100),
    branch_id uuid NOT NULL,
    break_end timestamp(6) without time zone,
    break_start timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    reason character varying(200),
    worker_id bigint NOT NULL
);


--
-- Name: worker_commission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_commission (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    commission_amount numeric(18,2),
    commission_rate numeric(10,4),
    created_at timestamp(6) without time zone NOT NULL,
    paid_at timestamp(6) without time zone,
    period_end date NOT NULL,
    period_start date NOT NULL,
    status character varying(30) NOT NULL,
    total_buys numeric(18,2),
    total_fees numeric(18,2),
    total_sales numeric(18,2),
    updated_at timestamp(6) without time zone,
    worker_id bigint NOT NULL,
    CONSTRAINT worker_commission_status_check CHECK (((status)::text = ANY ((ARRAY['CALCULATED'::character varying, 'APPROVED'::character varying, 'PAID'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: worker_competition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_competition (
    id uuid NOT NULL,
    competition_name character varying(255) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    end_date date NOT NULL,
    rules text,
    start_date date NOT NULL,
    status character varying(20) NOT NULL,
    updated_at timestamp(6) without time zone,
    CONSTRAINT worker_competition_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'CLOSED'::character varying])::text[])))
);


--
-- Name: worker_competition_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_competition_entry (
    id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    rank integer,
    score numeric(18,4) NOT NULL,
    total_volume numeric(18,2) NOT NULL,
    transaction_count integer NOT NULL,
    updated_at timestamp(6) without time zone,
    worker_id bigint NOT NULL,
    competition_id uuid NOT NULL
);


--
-- Name: worker_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_id_seq OWNED BY public.worker.id;


--
-- Name: worker_role_assignment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_role_assignment (
    id bigint NOT NULL,
    assigned_at timestamp(6) without time zone,
    is_primary boolean,
    role_def_id integer NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: worker_role_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_role_assignment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_role_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_role_assignment_id_seq OWNED BY public.worker_role_assignment.id;


--
-- Name: worker_role_def; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_role_def (
    id integer NOT NULL,
    code character varying(20) NOT NULL,
    description_hu character varying(500),
    name_hu character varying(100) NOT NULL
);


--
-- Name: worker_role_def_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_role_def_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_role_def_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_role_def_id_seq OWNED BY public.worker_role_def.id;


--
-- Name: worker_role_permission; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_role_permission (
    permission_id uuid NOT NULL,
    role_def_id integer NOT NULL,
    access_level character varying(20)
);


--
-- Name: worker_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.worker_session (
    id bigint NOT NULL,
    ip_address character varying(45),
    login_at timestamp(6) without time zone NOT NULL,
    logout_at timestamp(6) without time zone,
    token_id character varying(100),
    user_agent character varying(255),
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL,
    worker_id bigint NOT NULL
);


--
-- Name: worker_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.worker_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: worker_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.worker_session_id_seq OWNED BY public.worker_session.id;


--
-- Name: workstation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workstation (
    id uuid NOT NULL,
    branch_id uuid NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    ip_address character varying(45),
    is_active boolean NOT NULL,
    last_heartbeat timestamp(6) without time zone,
    mac_address character varying(17),
    name character varying(200) NOT NULL,
    updated_at timestamp(6) without time zone
);


--
-- Name: wu_balances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wu_balances (
    id uuid NOT NULL,
    huf_balance numeric(18,2) NOT NULL,
    last_receipt_buy character varying(50),
    last_receipt_customer_in character varying(50),
    last_receipt_customer_out character varying(50),
    last_receipt_sell character varying(50),
    updated_at timestamp(6) without time zone,
    usd_balance numeric(18,2) NOT NULL,
    branch_id uuid NOT NULL,
    company_id uuid NOT NULL
);


--
-- Name: wu_customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wu_customers (
    id uuid NOT NULL,
    address text,
    created_at timestamp(6) without time zone NOT NULL,
    date_of_birth date,
    first_name character varying(100) NOT NULL,
    id_number character varying(50),
    id_type character varying(50),
    last_name character varying(100) NOT NULL,
    nationality character varying(50),
    phone character varying(50),
    updated_at timestamp(6) without time zone,
    wu_customer_code character varying(50),
    customer_id bigint,
    company_id uuid
);


--
-- Name: wu_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wu_transactions (
    id uuid NOT NULL,
    amount_huf numeric(18,2),
    amount_usd numeric(18,2),
    created_at timestamp(6) without time zone NOT NULL,
    destination_country character varying(100),
    exchange_rate numeric(18,6),
    fee_amount numeric(18,2),
    mtcn character varying(20),
    receipt_number character varying(50),
    receiver_name character varying(200),
    sender_name character varying(200),
    status character varying(20) NOT NULL,
    transaction_date timestamp(6) without time zone NOT NULL,
    transaction_type character varying(10) NOT NULL,
    branch_id uuid NOT NULL,
    worker_id bigint,
    wu_customer_id uuid,
    reversed_transaction_id uuid,
    reversal_reason character varying(500),
    company_id uuid NOT NULL,
    CONSTRAINT chk_wu_transactions_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'COMPLETED'::character varying, 'REVERSED'::character varying, 'FAILED'::character varying])::text[]))),
    CONSTRAINT chk_wu_transactions_type CHECK (((transaction_type)::text = ANY ((ARRAY['SEND'::character varying, 'RECEIVE'::character varying, 'IC_IN'::character varying, 'IC_OUT'::character varying, 'CUSTOMER_IN'::character varying, 'CUSTOMER_OUT'::character varying, 'STORNO'::character varying])::text[])))
);


--
-- Name: archived_monthly_transaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_monthly_transaction ALTER COLUMN id SET DEFAULT nextval('public.archived_monthly_transaction_id_seq'::regclass);


--
-- Name: archived_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_transactions ALTER COLUMN id SET DEFAULT nextval('public.archived_transactions_id_seq'::regclass);


--
-- Name: cash_balance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance ALTER COLUMN id SET DEFAULT nextval('public.cash_balance_id_seq'::regclass);


--
-- Name: circular id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular ALTER COLUMN id SET DEFAULT nextval('public.circular_id_seq'::regclass);


--
-- Name: circular_acknowledgment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_acknowledgment ALTER COLUMN id SET DEFAULT nextval('public.circular_acknowledgment_id_seq'::regclass);


--
-- Name: circular_sequence id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_sequence ALTER COLUMN id SET DEFAULT nextval('public.circular_sequence_id_seq'::regclass);


--
-- Name: currency id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency ALTER COLUMN id SET DEFAULT nextval('public.currency_id_seq'::regclass);


--
-- Name: currency_stock id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_stock ALTER COLUMN id SET DEFAULT nextval('public.currency_stock_id_seq'::regclass);


--
-- Name: customer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer ALTER COLUMN id SET DEFAULT nextval('public.customer_id_seq'::regclass);


--
-- Name: daily_balance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_balance ALTER COLUMN id SET DEFAULT nextval('public.daily_balance_id_seq'::regclass);


--
-- Name: daily_report id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_report ALTER COLUMN id SET DEFAULT nextval('public.daily_report_id_seq'::regclass);


--
-- Name: daily_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session ALTER COLUMN id SET DEFAULT nextval('public.daily_session_id_seq'::regclass);


--
-- Name: denomination id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination ALTER COLUMN id SET DEFAULT nextval('public.denomination_id_seq'::regclass);


--
-- Name: employee id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee ALTER COLUMN id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- Name: employee_address id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_address ALTER COLUMN id SET DEFAULT nextval('public.employee_address_id_seq'::regclass);


--
-- Name: employee_bank_account id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_bank_account ALTER COLUMN id SET DEFAULT nextval('public.employee_bank_account_id_seq'::regclass);


--
-- Name: evening_sync_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evening_sync_log ALTER COLUMN id SET DEFAULT nextval('public.evening_sync_log_id_seq'::regclass);


--
-- Name: exchange_rate id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate ALTER COLUMN id SET DEFAULT nextval('public.exchange_rate_id_seq'::regclass);


--
-- Name: exchange_rate_source id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate_source ALTER COLUMN id SET DEFAULT nextval('public.exchange_rate_source_id_seq'::regclass);


--
-- Name: feor_code id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feor_code ALTER COLUMN id SET DEFAULT nextval('public.feor_code_id_seq'::regclass);


--
-- Name: handling_fee_bracket id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_bracket ALTER COLUMN id SET DEFAULT nextval('public.handling_fee_bracket_id_seq'::regclass);


--
-- Name: initial_fee_config id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initial_fee_config ALTER COLUMN id SET DEFAULT nextval('public.initial_fee_config_id_seq'::regclass);


--
-- Name: inventory_movement id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement ALTER COLUMN id SET DEFAULT nextval('public.inventory_movement_id_seq'::regclass);


--
-- Name: inventory_regeneration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_regeneration ALTER COLUMN id SET DEFAULT nextval('public.inventory_regeneration_id_seq'::regclass);


--
-- Name: inventory_summary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_summary ALTER COLUMN id SET DEFAULT nextval('public.inventory_summary_id_seq'::regclass);


--
-- Name: material_receipt id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt ALTER COLUMN id SET DEFAULT nextval('public.material_receipt_id_seq'::regclass);


--
-- Name: material_receipt_line id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt_line ALTER COLUMN id SET DEFAULT nextval('public.material_receipt_line_id_seq'::regclass);


--
-- Name: mnb_exchange_rate_cache id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_exchange_rate_cache ALTER COLUMN id SET DEFAULT nextval('public.mnb_exchange_rate_cache_id_seq'::regclass);


--
-- Name: monthly_closing_summary id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing_summary ALTER COLUMN id SET DEFAULT nextval('public.monthly_closing_summary_id_seq'::regclass);


--
-- Name: profit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_log ALTER COLUMN id SET DEFAULT nextval('public.profit_log_id_seq'::regclass);


--
-- Name: rate_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_history ALTER COLUMN id SET DEFAULT nextval('public.rate_history_id_seq'::regclass);


--
-- Name: receipt_sequence id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_sequence ALTER COLUMN id SET DEFAULT nextval('public.receipt_sequence_id_seq'::regclass);


--
-- Name: reservation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation ALTER COLUMN id SET DEFAULT nextval('public.reservation_id_seq'::regclass);


--
-- Name: rounding_rule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounding_rule ALTER COLUMN id SET DEFAULT nextval('public.rounding_rule_id_seq'::regclass);


--
-- Name: seal_tracking id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_tracking ALTER COLUMN id SET DEFAULT nextval('public.seal_tracking_id_seq'::regclass);


--
-- Name: stock_correction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_correction ALTER COLUMN id SET DEFAULT nextval('public.stock_correction_id_seq'::regclass);


--
-- Name: token_blacklist id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist ALTER COLUMN id SET DEFAULT nextval('public.token_blacklist_id_seq'::regclass);


--
-- Name: transaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction ALTER COLUMN id SET DEFAULT nextval('public.transaction_id_seq'::regclass);


--
-- Name: transaction_line id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_line ALTER COLUMN id SET DEFAULT nextval('public.transaction_line_id_seq'::regclass);


--
-- Name: transfer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer ALTER COLUMN id SET DEFAULT nextval('public.transfer_id_seq'::regclass);


--
-- Name: transfer_document id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document ALTER COLUMN id SET DEFAULT nextval('public.transfer_document_id_seq'::regclass);


--
-- Name: translation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation ALTER COLUMN id SET DEFAULT nextval('public.translation_id_seq'::regclass);


--
-- Name: vault_bank_transaction id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_bank_transaction ALTER COLUMN id SET DEFAULT nextval('public.vault_bank_transaction_id_seq'::regclass);


--
-- Name: vault_collection id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_collection ALTER COLUMN id SET DEFAULT nextval('public.vault_collection_id_seq'::regclass);


--
-- Name: vault_distribution id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_distribution ALTER COLUMN id SET DEFAULT nextval('public.vault_distribution_id_seq'::regclass);


--
-- Name: vault_distribution_line id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_distribution_line ALTER COLUMN id SET DEFAULT nextval('public.vault_distribution_line_id_seq'::regclass);


--
-- Name: vault_territory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_territory ALTER COLUMN id SET DEFAULT nextval('public.vault_territory_id_seq'::regclass);


--
-- Name: vault_transfer id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_transfer ALTER COLUMN id SET DEFAULT nextval('public.vault_transfer_id_seq'::regclass);


--
-- Name: worker id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker ALTER COLUMN id SET DEFAULT nextval('public.worker_id_seq'::regclass);


--
-- Name: worker_role_assignment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_assignment ALTER COLUMN id SET DEFAULT nextval('public.worker_role_assignment_id_seq'::regclass);


--
-- Name: worker_role_def id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_def ALTER COLUMN id SET DEFAULT nextval('public.worker_role_def_id_seq'::regclass);


--
-- Name: worker_session id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_session ALTER COLUMN id SET DEFAULT nextval('public.worker_session_id_seq'::regclass);


--
-- Data for Name: aml_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.aml_report (id, acknowledged_at, amount_huf, created_at, created_by, currency_code, customer_id, customer_name, document_number, document_type, external_reference, original_amount, report_type, reviewed_at, reviewed_by, risk_level, status, submitted_at, updated_at, worker_notes, company_id, transaction_id) FROM stdin;
\.


--
-- Data for Name: aml_threshold; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.aml_threshold (id, amount_huf, created_at, description, is_active, threshold_type, updated_at) FROM stdin;
\.


--
-- Data for Name: anonymous_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.anonymous_report (id, assigned_to_id, description, report_type, reported_at, resolution, status, subject) FROM stdin;
\.


--
-- Data for Name: archive_task; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.archive_task (id, archive_location, completed_at, criteria, entity_type, started_at, status, task_type) FROM stdin;
\.


--
-- Data for Name: archived_monthly_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.archived_monthly_transaction (id, monthly_closing_id, branch_id, company_id, original_tx_id, transaction_date, transaction_type, currency_code, currency_amount, huf_amount, exchange_rate, handling_fee, customer_id, worker_id, archived_at, year_month) FROM stdin;
\.


--
-- Data for Name: archived_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.archived_transactions (id, amount, archive_month, archive_status, archived_at, archived_by, branch_id, currency_code, customer_id, customer_name, document_number, exchange_rate, handling_fee, huf_amount, original_date, original_id, receipt_number, rounding_amount, transaction_type, worker_id, company_id) FROM stdin;
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_log (id, action, branch_id, branch_name, changes, created_at, entity_id, entity_type, ip_address, new_value, old_value, reason, user_agent, user_id, user_name, company_id) FROM stdin;
\.


--
-- Data for Name: authorization_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.authorization_log (id, action, performed_at, performed_by_worker_id, representative_id, transaction_id) FROM stdin;
\.


--
-- Data for Name: authorized_representative; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.authorized_representative (id, authorization_end, authorization_start, created_at, customer_id, is_active, representative_document_number, representative_document_type, representative_name) FROM stdin;
\.


--
-- Data for Name: backup_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.backup_record (id, backup_type, completed_at, created_at, created_by, file_path, file_size_bytes, started_at, status) FROM stdin;
\.


--
-- Data for Name: branch; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.branch (id, address, bank_code, city, code, created_at, denomination_rule_id, email, is_active, name, opening_date, phone, updated_at, vault_territory_id, zip_code, branch_status_did, branch_type_did, company_id, country_did, parent_branch_id, region_code) FROM stdin;
dd29ef03-c7cc-4fb8-9106-045991627a85	Tisza Sarok, Szeged	TISZA	Szeged	TISZA	2026-03-13 16:56:22.447612	\N	\N	t	Tisza Sarok	2026-03-13	\N	\N	\N	6720	a5c62cb0-c5a2-4863-8b92-ca23b469debe	2371b4da-5359-41e3-a785-f51f848cdebd	17015396-a878-4677-ab8e-05f2f7a8ee6c	72a437fc-133e-41f9-9cba-8af91e7d121c	\N	\N
8129b5a1-25f3-46a0-a02a-02f1f34ddd34	Korut 22, Szeged	KORUT	Szeged	KORUT	2026-03-16 12:51:15.228821	\N	\N	t	Korut	2026-03-16	\N	\N	\N	6722	a5c62cb0-c5a2-4863-8b92-ca23b469debe	2371b4da-5359-41e3-a785-f51f848cdebd	17015396-a878-4677-ab8e-05f2f7a8ee6c	72a437fc-133e-41f9-9cba-8af91e7d121c	\N	\N
\.


--
-- Data for Name: branch_group; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.branch_group (id, code, created_at, description, group_type_did, is_active, name, parent_group_id, updated_at) FROM stdin;
\.


--
-- Data for Name: branch_group_branches; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.branch_group_branches (branch_group_id, branch_id) FROM stdin;
\.


--
-- Data for Name: branch_status; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.branch_status (id, branch_id, created_at, daily_transaction_count, daily_volume_huf, is_online, last_heartbeat, last_sync, last_transaction_at, open_alerts, updated_at) FROM stdin;
\.


--
-- Data for Name: camera_access_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_access_log (id, action, created_at, ip_address, worker_id, recording_id) FROM stdin;
\.


--
-- Data for Name: camera_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_config (id, branch_id, camera_id, camera_name, created_at, device_index, enabled, fps, jpeg_quality, local_storage_path, resolution_height, resolution_width) FROM stdin;
\.


--
-- Data for Name: camera_export_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_export_request (id, branch_id, camera_id, period_from, period_to, reason, reference_number, status, requested_by, created_at, approved_by, approved_at, rejection_reason, export_path, export_size_bytes, manifest_hash, completed_at, error_message) FROM stdin;
\.


--
-- Data for Name: camera_recording; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_recording (id, branch_id, camera_id, created_at, end_time, expires_at, file_size_bytes, local_file_path, server_file_path, start_time, status, upload_attempts, uploaded_to_server) FROM stdin;
\.


--
-- Data for Name: camera_segment_hash; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_segment_hash (id, recording_id, branch_id, camera_id, sequence_number, file_hash, previous_hash, chain_hash, file_path, file_size_bytes, created_at) FROM stdin;
\.


--
-- Data for Name: camera_transaction_link; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.camera_transaction_link (id, created_at, frame_offset_seconds, receipt_number, transaction_id, transaction_time, recording_id) FROM stdin;
\.


--
-- Data for Name: cash_balance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cash_balance (id, created_at, current_balance, last_transaction_at, max_balance, min_balance, opening_balance, updated_at, version, branch_id, company_id, currency_id) FROM stdin;
4	2026-03-16 12:51:15.228821	1800000.00	2026-03-16 12:51:15.228821	4500000.00	1000000.00	1500000.00	2026-03-16 12:51:15.228821	0	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
5	2026-03-16 12:51:15.228821	5200.00	2026-03-16 12:51:15.228821	10000.00	1800.00	4500.00	2026-03-16 12:51:15.228821	0	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
6	2026-03-16 12:51:15.228821	4100.00	2026-03-16 12:51:15.228821	9000.00	1500.00	3600.00	2026-03-16 12:51:15.228821	0	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	5
1	2026-03-16 12:51:15.228821	2500000.00	2026-03-16 12:51:15.228821	6000000.00	1500000.00	2500000.00	2026-03-23 10:47:07.971847	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
2	2026-03-16 12:51:15.228821	8500.00	2026-03-16 12:51:15.228821	15000.00	3000.00	8500.00	2026-03-23 10:47:07.973952	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
3	2026-03-16 12:51:15.228821	6000.00	2026-03-16 12:51:15.228821	12000.00	2000.00	6000.00	2026-03-23 10:47:07.97406	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	5
\.


--
-- Data for Name: cash_desk_break; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cash_desk_break (id, break_end, break_start, break_type, cash_desk_id, created_at, is_active, reason) FROM stdin;
\.


--
-- Data for Name: cash_register_event; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.cash_register_event (id, amount, amount_huf, cash_register_id, created_at, currency_code, event_timestamp, event_type, raw_response, receipt_number, tax_number, branch_id) FROM stdin;
\.


--
-- Data for Name: chain_of_custody_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chain_of_custody_record (id, export_request_id, branch_id, camera_id, event_type, actor, event_timestamp, details, period_from, period_to, source_ip, manifest_hash) FROM stdin;
\.


--
-- Data for Name: circular; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.circular (id, acknowledged, acknowledged_at, attachment_filename, attachment_mime_type, attachment_path, circular_type, content, created_at, priority, registration_number, target, target_branch_id, target_company_id, title, urgent, valid_from, valid_to, created_by_id, company_id, archived, archived_at, archive_year, category, attachment_size) FROM stdin;
\.


--
-- Data for Name: circular_acknowledgment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.circular_acknowledgment (id, circular_id, worker_id, acknowledged_at, ip_address) FROM stdin;
\.


--
-- Data for Name: circular_sequence; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.circular_sequence (id, company_id, prefix, last_number) FROM stdin;
\.


--
-- Data for Name: closing_control; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.closing_control (id, alert_level, branch_id, company_id, control_date, created_at, daily_closing_done, evening_closing_done, last_transaction_at, nav_closing_done, notes, updated_at) FROM stdin;
\.


--
-- Data for Name: closing_wizard; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.closing_wizard (id, cash_desk_id, closing_date, closing_type, completed_at, current_step, notes, started_at, total_steps, wizard_status, branch_id, completed_by_worker_id, started_by_worker_id) FROM stdin;
854e1652-ddfa-49ac-b0c5-c4a1ae04d27b	\N	2026-03-18	DAILY	\N	1	\N	2026-03-18 08:24:19.956412	10	IN_PROGRESS	dd29ef03-c7cc-4fb8-9106-045991627a85	\N	2
\.


--
-- Data for Name: closing_wizard_step; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.closing_wizard_step (id, can_proceed, completed, step_data, step_description, step_number, step_title, wizard_id) FROM stdin;
c0eaa024-10d5-4361-98e9-d2342b654a64	t	f	{"legacyStepNumber":1}	Napi / dekád / havi / POS zárás típusának kiválasztása	1	Zárás típus kiválasztása	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
3cf10164-7e09-4bee-80af-e3427248e9d8	t	f	{"legacyStepNumber":2}	Napi tranzakciók összesítése valutánként (vétel, eladás, konverzió)	2	Napi tranzakció összesítés	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
d0fbca44-66e3-4d39-b49b-b0379214ec56	t	f	{"legacyStepNumber":3}	Készpénz nyitó- és záró egyenleg ellenőrzése valutánként, címletezéssel	3	Pénztár nyitó/záró egyenleg	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
f6613f1e-5f03-4966-b9ee-8bfe699aa158	t	f	{"legacyStepNumber":4}	Kezelési díjak összesítése és címletezése	4	Kezelési díj összesítés	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
1670da43-0535-41d2-8b21-9ad018cdcb3e	t	f	{"legacyStepNumber":5}	Pénztárak közötti valuta- és forintmozgások ellenőrzése (göngyöleg/transzfer)	5	Irodák közti mozgások	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
e16fdc0d-e882-4739-9d5b-ae57ab3e9b06	t	f	{"legacyStepNumber":6}	Ellenőrzi hogy a napi árfolyamok érvényesek-e (24h TTL) és egyeznek a használtakkal	6	Napi árfolyam ellenőrzés	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
9e965b91-01d0-4df7-82b7-7520df76021e	t	f	{"legacyStepNumber":13}	Napi/dekád/havi/POS zárási bizonylatok nyomtatása	7	Zárási bizonylatok nyomtatása	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
6d962c9d-2a2f-494e-8f0f-bdaff49e214a	t	f	{"legacyStepNumber":14}	Forint átutalási bizonylatok nyomtatása (FF/UF)	8	HUF átutalási bizonylatok	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
492bb17e-457a-4bc6-8fcb-25b449cf0d03	t	f	{"legacyStepNumber":15}	Napi jelentések küldése a központba (legacy: FTP, modern: REST API)	9	Napi jelentések küldése	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
c8d25435-96a7-4ff3-9708-59d8bbe58b91	t	f	{"legacyStepNumber":16}	Dekád/havi jelentések küldése a központba és a zárás véglegesítése	10	Időszaki jelentések + véglegesítés	854e1652-ddfa-49ac-b0c5-c4a1ae04d27b
\.


--
-- Data for Name: collected_inventory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.collected_inventory (id, amount, currency_code, denomination_details, huf_value, data_collection_id) FROM stdin;
dcae9bb4-7af8-4559-b6b3-6175b5754d68	2500000.00	HUF	\N	0.00	3b25d16b-0372-41bc-aa63-ae7681deda95
5e630e56-d249-4d27-98b1-a2797dcaf15c	8500.00	EUR	\N	0.00	3b25d16b-0372-41bc-aa63-ae7681deda95
cc67c5e8-b608-4bb7-b06e-e487b14413c7	6000.00	USD	\N	0.00	3b25d16b-0372-41bc-aa63-ae7681deda95
44cc25bd-9f94-4124-8447-909d4f663241	1800000.00	HUF	\N	0.00	ff9c73af-882f-4442-8898-0d667ccd33ba
c889b0b9-b820-479b-a191-cc9e412dc9b6	5200.00	EUR	\N	0.00	ff9c73af-882f-4442-8898-0d667ccd33ba
822f705d-bae8-46c0-ad0e-11803358717d	4100.00	USD	\N	0.00	ff9c73af-882f-4442-8898-0d667ccd33ba
9c6bc773-a73d-4019-b9c6-1a8a64e6872e	2500000.00	HUF	\N	0.00	748d231a-f68a-4953-b4ac-f34a99a590a9
12dded45-c1d0-49b1-95d1-32ff264c2d13	8500.00	EUR	\N	0.00	748d231a-f68a-4953-b4ac-f34a99a590a9
7bef768d-674a-47b4-bcfd-18cce044735e	6000.00	USD	\N	0.00	748d231a-f68a-4953-b4ac-f34a99a590a9
8b2cb07f-0182-460e-a93f-5d868f575db2	1800000.00	HUF	\N	0.00	74deb61c-8388-4d14-875b-24bea88cc4af
7e0b118b-3100-4871-9a57-ffd5b17fb325	5200.00	EUR	\N	0.00	74deb61c-8388-4d14-875b-24bea88cc4af
256c3c47-43dd-46e7-8747-aac9898bbf8c	4100.00	USD	\N	0.00	74deb61c-8388-4d14-875b-24bea88cc4af
92c9967a-896a-46fd-922b-131425d8437b	2500000.00	HUF	\N	0.00	3cfe2299-8209-4b6a-bdb5-1b2ed1316d85
ee2453fc-aa74-4be0-8466-02720ebafe7b	8500.00	EUR	\N	0.00	3cfe2299-8209-4b6a-bdb5-1b2ed1316d85
d1510dbb-3e0d-4060-8c10-ba3f77d9287d	6000.00	USD	\N	0.00	3cfe2299-8209-4b6a-bdb5-1b2ed1316d85
8ab43106-db03-4220-abe5-fca0adea16e7	1800000.00	HUF	\N	0.00	79f1a0cd-1741-434f-b498-45201d282b17
0c92540a-0871-4099-9380-c80b5b81b083	5200.00	EUR	\N	0.00	79f1a0cd-1741-434f-b498-45201d282b17
76876a2e-b4a1-455c-9330-b47f53b53c0b	4100.00	USD	\N	0.00	79f1a0cd-1741-434f-b498-45201d282b17
e08cc399-7f95-4610-9255-309640632f08	2500000.00	HUF	\N	0.00	f4bc3cfc-0fe9-44c3-bdae-02e110a3a797
e7ef122b-504c-463f-915c-986f0cdc57b0	8500.00	EUR	\N	0.00	f4bc3cfc-0fe9-44c3-bdae-02e110a3a797
f77bb2b7-38cb-48eb-844b-aec0cf5ff393	6000.00	USD	\N	0.00	f4bc3cfc-0fe9-44c3-bdae-02e110a3a797
aa7d370d-95cf-48d4-a6b2-7830e3b92685	1800000.00	HUF	\N	0.00	d6285a44-0111-462d-9873-8a8536080f1f
3c974e4a-1966-4e32-b12b-31a961bed308	5200.00	EUR	\N	0.00	d6285a44-0111-462d-9873-8a8536080f1f
22a8aa63-9a8c-4a34-96cc-7aa437d18e9d	4100.00	USD	\N	0.00	d6285a44-0111-462d-9873-8a8536080f1f
d2204af9-96e9-4347-b7b8-439e5c7df58d	2500000.00	HUF	\N	0.00	1914d254-7e1a-4cc1-8d8f-c769d3669507
13b0ef29-1848-4fce-866b-e05522a2d5d7	8500.00	EUR	\N	0.00	1914d254-7e1a-4cc1-8d8f-c769d3669507
450fc50d-93b7-496c-b3f5-3ffb12bb0643	6000.00	USD	\N	0.00	1914d254-7e1a-4cc1-8d8f-c769d3669507
095ba71b-213f-487d-a72f-89766f028119	1800000.00	HUF	\N	0.00	e76c8127-afdd-4711-b45e-a903687991de
39ae2b6f-5664-49ae-a4f5-e44761eb739d	5200.00	EUR	\N	0.00	e76c8127-afdd-4711-b45e-a903687991de
ae8729b7-3d7c-44fa-ab25-16221a86a311	4100.00	USD	\N	0.00	e76c8127-afdd-4711-b45e-a903687991de
82c82646-7ccf-48e2-9af0-b37e7182af38	2500000.00	HUF	\N	0.00	711dc465-124f-4459-839a-8d318c47c888
fdd6ff90-db16-49a9-8fde-689f7244c9c4	8500.00	EUR	\N	0.00	711dc465-124f-4459-839a-8d318c47c888
fc1ad5bb-23ec-45e4-8332-6192d36b79de	6000.00	USD	\N	0.00	711dc465-124f-4459-839a-8d318c47c888
56c7bfb5-0359-40d7-808c-a942f95c7f36	1800000.00	HUF	\N	0.00	ae36a343-97eb-432c-9654-7c871250776d
0d31c096-efdf-4271-a8a9-4d0beadbe41e	5200.00	EUR	\N	0.00	ae36a343-97eb-432c-9654-7c871250776d
771ce428-4a7c-4f49-bcbc-c1fa1373398f	4100.00	USD	\N	0.00	ae36a343-97eb-432c-9654-7c871250776d
18ed0f35-43f8-4a8a-850c-41cbf2d556c9	2500000.00	HUF	\N	0.00	39e37c1a-1881-4306-be06-eb79af0e943a
2e0d2e23-595b-450d-9bfc-755166c3bd3c	8500.00	EUR	\N	0.00	39e37c1a-1881-4306-be06-eb79af0e943a
e5f2f1ce-f8be-4649-a631-82551d37b28e	6000.00	USD	\N	0.00	39e37c1a-1881-4306-be06-eb79af0e943a
57f5c2c4-0ca6-4771-a83f-97f9dafdb245	1800000.00	HUF	\N	0.00	7dfd6a73-56e2-4576-ab16-17dcbff92aab
5ed3f643-5896-4a7f-b66b-70d4666815b9	5200.00	EUR	\N	0.00	7dfd6a73-56e2-4576-ab16-17dcbff92aab
90f2d652-79b5-4227-8aea-b626115f1137	4100.00	USD	\N	0.00	7dfd6a73-56e2-4576-ab16-17dcbff92aab
0b6ae606-e346-4f74-b2dc-0ab586e7fe3d	2500000.00	HUF	\N	0.00	0ccc57d9-0c3b-4bb0-80f5-e383af1f17b6
a8d3087c-e0db-4039-ba5a-0cfa3ccd4505	8500.00	EUR	\N	0.00	0ccc57d9-0c3b-4bb0-80f5-e383af1f17b6
98831231-4f95-4c2c-b363-55b7e5751ea8	6000.00	USD	\N	0.00	0ccc57d9-0c3b-4bb0-80f5-e383af1f17b6
229cd137-85eb-4f12-9898-b20d98931049	1800000.00	HUF	\N	0.00	120dfbcf-039e-45e1-be66-c0a7c2f6e356
16b16f99-0c55-48c9-9a19-6a18976ee83a	5200.00	EUR	\N	0.00	120dfbcf-039e-45e1-be66-c0a7c2f6e356
9f9f0be8-d985-45f4-8551-5598306ce1f7	4100.00	USD	\N	0.00	120dfbcf-039e-45e1-be66-c0a7c2f6e356
\.


--
-- Data for Name: collected_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.collected_transaction (id, currency_code, customer_name, foreign_amount, huf_amount, original_transaction_id, rate, receipt_number, transaction_timestamp, transaction_type, data_collection_id) FROM stdin;
\.


--
-- Data for Name: commission_calculation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commission_calculation (id, approved_at, approved_by, bonus_amount, branch_id, calculated_at, calculation_type, commission_amount, commission_rate, created_at, deductions, net_commission, period, status, total_transactions, total_volume_huf, worker_id) FROM stdin;
\.


--
-- Data for Name: commission_rate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commission_rate (id, created_at, currency_id, entity_id, entity_type, is_active, rate, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: commission_rule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.commission_rule (id, bonus_percent, bonus_threshold, company_id, created_at, max_volume_huf, min_volume_huf, rate_percent, tier, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: company; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.company (id, address, code, created_at, email, is_active, name, phone, registration_number, tax_number, updated_at) FROM stdin;
17015396-a878-4677-ab8e-05f2f7a8ee6c	\N	EBC	2026-03-13 16:56:22.447612	\N	t	Exclusive Best Change Zrt.	\N	\N	\N	\N
\.


--
-- Data for Name: competitor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competitor (id, branch_id, created_at, is_active, name, updated_at, website) FROM stdin;
\.


--
-- Data for Name: competitor_rates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.competitor_rates (id, competitor_id, currency_id, buy_rate, sell_rate, rate_date, source, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: contribution; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.contribution (id, amount, branch_id, calculated_at, contribution_type, created_at, currency_id, period_end, period_start, status, updated_at) FROM stdin;
\.


--
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currency (id, is_active, code, created_at, decimal_places, default_buy_spread, default_sell_spread, display_order, flag_icon, max_transaction_amount, min_transaction_amount, name, symbol, updated_at, max_deviation_percent) FROM stdin;
3	t	HUF	2026-03-13 17:16:32.653346	0	\N	\N	\N	\N	\N	\N	Magyar Forint	\N	\N	\N
4	t	EUR	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Euro	\N	\N	\N
5	t	USD	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	US Dollar	\N	\N	\N
6	t	GBP	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Brit Font	\N	\N	\N
7	t	CHF	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Svajci Frank	\N	\N	\N
8	t	CZK	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Cseh Korona	\N	\N	\N
9	t	PLN	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Lengyel Zloty	\N	\N	\N
10	t	RON	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Roman Lej	\N	\N	\N
11	t	SEK	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Sved Korona	\N	\N	\N
12	t	NOK	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Norweg Korona	\N	\N	\N
13	t	DKK	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Dan Korona	\N	\N	\N
14	t	JPY	2026-03-13 17:16:32.653346	0	\N	\N	\N	\N	\N	\N	Japan Jen	\N	\N	\N
15	t	CAD	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Kanadai Dollar	\N	\N	\N
16	t	AUD	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Ausztal Dollar	\N	\N	\N
17	t	CNY	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Kinai Juan	\N	\N	\N
18	t	RUB	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Orosz Rubel	\N	\N	\N
19	t	UAH	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Ukran Hrivnya	\N	\N	\N
20	t	TRY	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Torok Lira	\N	\N	\N
21	f	SKK	2026-03-13 17:16:32.653346	2	\N	\N	\N	\N	\N	\N	Szlovak Korona	\N	\N	\N
\.


--
-- Data for Name: currency_group; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currency_group (id, code, created_at, currency_ids, description, is_active, name, updated_at) FROM stdin;
\.


--
-- Data for Name: currency_stock; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.currency_stock (id, currency_code, entity_id, entity_type, last_updated, quantity, weighted_avg_cost, company_id) FROM stdin;
1	EUR	dd29ef03-c7cc-4fb8-9106-045991627a85	CASHIER	2026-03-16 12:51:15.228821	8500.00	388.7000	17015396-a878-4677-ab8e-05f2f7a8ee6c
2	USD	dd29ef03-c7cc-4fb8-9106-045991627a85	CASHIER	2026-03-16 12:51:15.228821	6000.00	338.2000	17015396-a878-4677-ab8e-05f2f7a8ee6c
3	EUR	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	CASHIER	2026-03-16 12:51:15.228821	5200.00	389.1000	17015396-a878-4677-ab8e-05f2f7a8ee6c
4	USD	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	CASHIER	2026-03-16 12:51:15.228821	4100.00	338.8000	17015396-a878-4677-ab8e-05f2f7a8ee6c
\.


--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer (id, active, address, birth_date, birth_name, birth_place, city, company_name, country, created_at, customer_code, customer_type, document_expiry, document_number, document_type, email, id_card_expiry, id_card_number, is_company, is_foreign, is_pep, is_vip, last_transaction_date, mother_name, name, nationality, notes, passport_expiry, passport_number, phone, postal_code, registration_number, tax_number, transaction_count, updated_at, company_id, high_risk_flag, high_risk_reason, high_risk_set_at) FROM stdin;
\.


--
-- Data for Name: customer_restriction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_restriction (id, is_active, added_at, added_by, customer_id, expires_at, reason, restriction_type) FROM stdin;
\.


--
-- Data for Name: customer_screening_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.customer_screening_log (id, customer_id, details, result, screened_at, screened_by, screening_type) FROM stdin;
\.


--
-- Data for Name: daily_balance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_balance (id, actual_stock, balance_date, branch_id, closed_at, closed_by, closing_balance, created_at, currency_code, difference, difference_note, is_closed, opening_balance, purchases, sales, transfers_in, transfers_out, company_id) FROM stdin;
\.


--
-- Data for Name: daily_checklist; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_checklist (id, company_id, branch_id, checklist_date, worker_id, status, completed_at, created_at) FROM stdin;
\.


--
-- Data for Name: daily_checklist_item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_checklist_item (id, checklist_id, item_number, item_title, item_description, checked, checked_at, checked_by_worker_id, notes) FROM stdin;
\.


--
-- Data for Name: daily_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_report (id, created_at, report_data, report_date, submitted, submitted_at, total_buy_huf, total_fee_huf, total_profit, total_sell_huf, transaction_count, branch_id, submitted_by_id) FROM stdin;
\.


--
-- Data for Name: daily_session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.daily_session (id, buy_count, buy_turnover_huf, closed_at, closing_balance_huf, created_at, denomination_verified, handling_fee_total, nav_uploaded, notes, opened_at, opening_balance_huf, qr_code_generated, reversal_count, sell_count, sell_turnover_huf, session_date, status, transaction_count, updated_at, branch_id, closed_by_worker_id, company_id, opened_by_worker_id) FROM stdin;
16	0	0.00	\N	\N	2026-03-23 10:47:07.948683	f	0.00	f	\N	2026-03-23 10:47:07.947158	2500000.00	f	0	0	0.00	2026-03-23	OPEN	0	2026-03-23 10:47:07.948683	dd29ef03-c7cc-4fb8-9106-045991627a85	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
\.


--
-- Data for Name: darius_daily_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.darius_daily_report (id, company_id, report_date, status, total_buy_huf, total_sell_huf, transaction_count, total_handling_fee_huf, branch_count, payload, payload_format, payload_hash, submitted_at, submitted_by, ack_reference, ack_at, error_message, retry_count, max_retries, next_retry_at, approved_by, approved_at, created_at, updated_at, notes) FROM stdin;
\.


--
-- Data for Name: darius_report_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.darius_report_line (id, report_id, branch_id, branch_code, currency_code, buy_count, buy_currency_amount, buy_huf_amount, sell_count, sell_currency_amount, sell_huf_amount, avg_buy_rate, avg_sell_rate, handling_fee_huf) FROM stdin;
\.


--
-- Data for Name: data_collection; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_collection (id, collection_date, collection_type, completed_at, created_at, error_message, started_at, status, total_buy_huf, total_sell_huf, transaction_count, updated_at, branch_id) FROM stdin;
c02b75db-6988-4792-8bb0-49e0f15d6b82	2026-03-13	DAILY	2026-03-13 22:00:00.071412	2026-03-13 22:00:00.073439	\N	2026-03-13 22:00:00.045238	COMPLETED	0.00	0.00	0	2026-03-13 22:00:00.073439	dd29ef03-c7cc-4fb8-9106-045991627a85
d3f3e33b-3874-41a7-816e-43813f2d7fde	2026-03-14	DAILY	2026-03-14 22:00:00.05284	2026-03-14 22:00:00.055146	\N	2026-03-14 22:00:00.032912	COMPLETED	0.00	0.00	0	2026-03-14 22:00:00.055146	dd29ef03-c7cc-4fb8-9106-045991627a85
62924eae-4389-45a0-baea-6df7ab2335b9	2026-03-15	DAILY	2026-03-15 22:00:00.398805	2026-03-15 22:00:00.675352	\N	2026-03-15 22:00:00.206395	COMPLETED	0.00	0.00	0	2026-03-15 22:00:00.675352	dd29ef03-c7cc-4fb8-9106-045991627a85
3b25d16b-0372-41bc-aa63-ae7681deda95	2026-03-16	DAILY	2026-03-16 22:00:00.084801	2026-03-16 22:00:00.096142	\N	2026-03-16 22:00:00.046771	COMPLETED	0.00	0.00	0	2026-03-16 22:00:00.096142	dd29ef03-c7cc-4fb8-9106-045991627a85
ff9c73af-882f-4442-8898-0d667ccd33ba	2026-03-16	DAILY	2026-03-16 22:00:00.179962	2026-03-16 22:00:00.180584	\N	2026-03-16 22:00:00.169171	COMPLETED	0.00	0.00	0	2026-03-16 22:00:00.180584	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
748d231a-f68a-4953-b4ac-f34a99a590a9	2026-03-17	DAILY	2026-03-17 22:00:00.052597	2026-03-17 22:00:00.05551	\N	2026-03-17 22:00:00.02468	COMPLETED	0.00	0.00	0	2026-03-17 22:00:00.05551	dd29ef03-c7cc-4fb8-9106-045991627a85
74deb61c-8388-4d14-875b-24bea88cc4af	2026-03-17	DAILY	2026-03-17 22:00:00.189575	2026-03-17 22:00:00.19004	\N	2026-03-17 22:00:00.172764	COMPLETED	0.00	0.00	0	2026-03-17 22:00:00.19004	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
3cfe2299-8209-4b6a-bdb5-1b2ed1316d85	2026-03-18	DAILY	2026-03-18 22:00:00.05278	2026-03-18 22:00:00.055694	\N	2026-03-18 22:00:00.029338	COMPLETED	0.00	0.00	0	2026-03-18 22:00:00.055694	dd29ef03-c7cc-4fb8-9106-045991627a85
79f1a0cd-1741-434f-b498-45201d282b17	2026-03-18	DAILY	2026-03-18 22:00:00.12557	2026-03-18 22:00:00.126086	\N	2026-03-18 22:00:00.11543	COMPLETED	0.00	0.00	0	2026-03-18 22:00:00.126086	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
f4bc3cfc-0fe9-44c3-bdae-02e110a3a797	2026-03-19	DAILY	2026-03-19 22:00:00.098758	2026-03-19 22:00:00.116169	\N	2026-03-19 22:00:00.057781	COMPLETED	0.00	0.00	0	2026-03-19 22:00:00.116169	dd29ef03-c7cc-4fb8-9106-045991627a85
d6285a44-0111-462d-9873-8a8536080f1f	2026-03-19	DAILY	2026-03-19 22:00:00.234457	2026-03-19 22:00:00.235178	\N	2026-03-19 22:00:00.221065	COMPLETED	0.00	0.00	0	2026-03-19 22:00:00.235178	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
1914d254-7e1a-4cc1-8d8f-c769d3669507	2026-03-20	DAILY	2026-03-20 22:00:00.107013	2026-03-20 22:00:00.113604	\N	2026-03-20 22:00:00.079388	COMPLETED	0.00	0.00	0	2026-03-20 22:00:00.113604	dd29ef03-c7cc-4fb8-9106-045991627a85
e76c8127-afdd-4711-b45e-a903687991de	2026-03-20	DAILY	2026-03-20 22:00:00.190219	2026-03-20 22:00:00.190658	\N	2026-03-20 22:00:00.179703	COMPLETED	0.00	0.00	0	2026-03-20 22:00:00.190658	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
711dc465-124f-4459-839a-8d318c47c888	2026-03-21	DAILY	2026-03-21 22:00:00.623279	2026-03-21 22:00:00.82205	\N	2026-03-21 22:00:00.575666	COMPLETED	0.00	0.00	0	2026-03-21 22:00:00.82205	dd29ef03-c7cc-4fb8-9106-045991627a85
ae36a343-97eb-432c-9654-7c871250776d	2026-03-21	DAILY	2026-03-21 22:00:01.150569	2026-03-21 22:00:01.151268	\N	2026-03-21 22:00:01.13796	COMPLETED	0.00	0.00	0	2026-03-21 22:00:01.151268	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
39e37c1a-1881-4306-be06-eb79af0e943a	2026-03-22	DAILY	2026-03-22 22:00:00.052828	2026-03-22 22:00:00.053428	\N	2026-03-22 22:00:00.02861	COMPLETED	0.00	0.00	0	2026-03-22 22:00:00.053428	dd29ef03-c7cc-4fb8-9106-045991627a85
7dfd6a73-56e2-4576-ab16-17dcbff92aab	2026-03-22	DAILY	2026-03-22 22:00:00.091859	2026-03-22 22:00:00.092427	\N	2026-03-22 22:00:00.08036	COMPLETED	0.00	0.00	0	2026-03-22 22:00:00.092427	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
0ccc57d9-0c3b-4bb0-80f5-e383af1f17b6	2026-03-23	DAILY	2026-03-23 22:00:00.121057	2026-03-23 22:00:00.128218	\N	2026-03-23 22:00:00.046052	COMPLETED	0.00	0.00	0	2026-03-23 22:00:00.128218	dd29ef03-c7cc-4fb8-9106-045991627a85
120dfbcf-039e-45e1-be66-c0a7c2f6e356	2026-03-23	DAILY	2026-03-23 22:00:00.240073	2026-03-23 22:00:00.240708	\N	2026-03-23 22:00:00.229946	COMPLETED	0.00	0.00	0	2026-03-23 22:00:00.240708	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
\.


--
-- Data for Name: data_import_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.data_import_jobs (id, completed_at, created_at, error_log, failed_records, import_type, imported_records, source_file, source_type, started_at, status, total_records, updated_at, branch_id) FROM stdin;
\.


--
-- Data for Name: decade_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.decade_report (id, closed_at, closed_by, created_at, decade, status, total_buy_huf, total_handling_fee, total_sell_huf, transaction_count, updated_at, year, branch_id, opening_inventory_value_huf, closing_inventory_value_huf, decade_profit_huf, forint_opening, forint_total_income, forint_total_expense, forint_closing, forint_control_valid, forint_control_diff, first_receipt_number, last_receipt_number, card_payment_total, print_control_flag) FROM stdin;
\.


--
-- Data for Name: decade_report_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.decade_report_line (id, decade_report_id, currency_code, opening_balance, opening_mnb_rate, opening_value_huf, closing_balance, closing_mnb_rate, closing_value_huf, profit_huf, created_at) FROM stdin;
\.


--
-- Data for Name: denomination; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.denomination (id, active, created_at, denomination_type, face_value, max_quantity, min_quantity, quantity, updated_at, branch_id, company_id, currency_id) FROM stdin;
\.


--
-- Data for Name: denomination_balance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.denomination_balance (id, cash_desk_id, quantity, total_value, updated_at, denomination_id, denomination_category) FROM stdin;
\.


--
-- Data for Name: denomination_count; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.denomination_count (id, branch_id, count_type, created_at, currency_code, face_value, quantity, session_id, worker_id, denomination_category) FROM stdin;
\.


--
-- Data for Name: dictionary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dictionary (id, category, code, created_at, description, is_active, name, name_hu, sort_order, updated_at) FROM stdin;
a5c62cb0-c5a2-4863-8b92-ca23b469debe	BRANCH_STATUS	ACTIVE	2026-03-13 16:56:22.447612	\N	t	Active	Aktiv	1	\N
2371b4da-5359-41e3-a785-f51f848cdebd	BRANCH_TYPE	PENZTAR	2026-03-13 16:56:22.447612	\N	t	Cash Office	Penztar	4	\N
72a437fc-133e-41f9-9cba-8af91e7d121c	COUNTRY	HU	2026-03-13 16:56:22.447612	\N	t	Hungary	Magyarorszag	1	\N
\.


--
-- Data for Name: document; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.document (id, entity_id, entity_type, file_data, file_name, file_size, file_type, uploaded_at, uploaded_by_id, company_id) FROM stdin;
\.


--
-- Data for Name: email_account; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_account (id, created_at, display_name, gmail_address, is_active, last_sync_at, oauth_access_token, oauth_refresh_token, oauth_token_expiry, sync_error, updated_at, branch_id, configured_by_worker_id, own_company_id, vault_territory_id, worker_id) FROM stdin;
\.


--
-- Data for Name: email_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.email_cache (id, cached_at, gmail_message_id, has_attachments, is_read, is_starred, label_ids, received_at, recipients, sender_address, snippet, subject, thread_id, email_account_id) FROM stdin;
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee (id, is_active, birth_country, birth_date, birth_first_name, birth_last_name, birth_place, certificate_date, citizenship, created_at, created_by, credit_validity_last_month, email, employment_end_date, employment_start_date, employment_type, family_tax_credit, feor_code, first_marriage_credit, first_name, four_plus_children_credit, has_secondary_education, id_card_expiry, id_card_number, job_title, last_name, marriage_date, mothers_name, organization_unit, payment_method, pension_start_date, pension_type, personal_tax_credit, phone, reduced_work_capacity, reduced_work_capacity_type, salary_amount, salary_type, serial_number, social_security_number, tax_id, three_children_credit, two_children_credit, under_25_youth_credit_amount, under_25_youth_credit_expiry, under_30_mother_credit_amount, updated_at, updated_by, vocational_qualification, vocational_school_name, work_hours_per_day, company_id, worker_id) FROM stdin;
\.


--
-- Data for Name: employee_address; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_address (id, address_type, building, city, door, floor, house_number, postal_code, staircase, street_name, street_type, employee_id) FROM stdin;
\.


--
-- Data for Name: employee_bank_account; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.employee_bank_account (id, account_number, account_type, bank_code, employee_id) FROM stdin;
\.


--
-- Data for Name: error_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.error_logs (id, app_name, browser, commit_sha, created_at, email_sent, email_sent_at, environment, error_type, fingerprint, first_seen_at, last_seen_at, message, occurrence_count, repo_path, request_body, request_id, request_method, resolved, resolved_at, resolved_commit, severity, stack, url, user_email, user_id) FROM stdin;
976882d2-432e-4028-a8db-63c55aa90c31	Valutaváltó ERP	\N	\N	2026-03-13 16:26:44.790276+00	t	2026-03-13 16:26:45.793587+00	production	api_error	d45c7968def9e338920a275bcf144cbc	2026-03-13 16:26:44.790275+00	2026-03-13 16:26:44.790275+00	No static resource actuator/mappings.	1	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.web.servlet.resource.NoResourceFoundException: No static resource actuator/mappings.\n\tat org.springframework.web.servlet.resource.ResourceHttpRequestHandler.handleRequest(ResourceHttpRequestHandler.java:585)\n\tat org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter.handle(HttpRequestHandlerAdapter.java:52)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat com.puzzleir.backend.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterCh	/actuator/mappings	\N	\N
018bad62-73d9-4d87-ba67-76b73f35aafb	Valutaváltó ERP	\N	\N	2026-03-13 08:35:06.745387+00	t	2026-03-13 08:45:27.5992+00	production	api_error	951134c61bf72fe753c28fedd1168a17	2026-03-13 08:35:06.745382+00	2026-03-13 08:49:16.724701+00	No static resource actuator/health.	86	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.web.servlet.resource.NoResourceFoundException: No static resource actuator/health.\n\tat org.springframework.web.servlet.resource.ResourceHttpRequestHandler.handleRequest(ResourceHttpRequestHandler.java:585)\n\tat org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter.handle(HttpRequestHandlerAdapter.java:52)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat com.puzzleir.backend.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:365)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.servletapi.SecurityContextHolderAwareRequestFilter.doFilter(SecurityContextHolderAwareRequestFilter.java:179)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.savedrequest.RequestCacheAwareFilter.doFilter(RequestCacheAwareFilter.java:63)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat hu.puzzleir.valuta.security.JwtAuthenticationFilter.doFilterInternal(JwtAuthenticationFilter.java:74)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.authentication.logout.LogoutFilter.doFilter(LogoutFilter.java:107)\n\tat org.springframework.security.web.authentication.logout.LogoutFilter.doFilter(LogoutFilter.java:93)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.web.filter.CorsFilter.doFilterInternal(CorsFilter.java:91)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.springframework.security.web.FilterChainProxy$VirtualFilterChain.doFilter(FilterChainProxy.java:374)\n\tat org.springframework.security.web.header.HeaderWriterFilter.doHeadersAfter(HeaderWriterFilter.java:90)\n\tat org.springframework.security.web.header.HeaderWriterFilter.doFilterIntern	/actuator/health	\N	\N
d6f7eef7-a404-4918-850a-eda66df77204	Valutaváltó ERP	\N	\N	2026-03-13 15:02:57.277851+00	t	2026-03-13 15:02:59.160186+00	production	api_error	0015e1d63e465b7b281d53ddc85e6a50	2026-03-13 15:02:57.277846+00	2026-03-13 15:02:57.277847+00	No static resource actuator/flyway.	1	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.web.servlet.resource.NoResourceFoundException: No static resource actuator/flyway.\n\tat org.springframework.web.servlet.resource.ResourceHttpRequestHandler.handleRequest(ResourceHttpRequestHandler.java:585)\n\tat org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter.handle(HttpRequestHandlerAdapter.java:52)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat com.puzzleir.backend.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:131)\n\tat org.springframework.security.web.session.SessionManagementFilter.doFilter(SessionManagementFilter.java:85)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.authentication.AnonymousAuthenticationFilter.doFilter(AnonymousAuthenticationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChai	/actuator/flyway	\N	\N
1129e5a9-4a45-4daa-a0e2-2905fc065f89	Valutaváltó ERP	\N	\N	2026-03-13 17:35:04.568694+00	f	\N	production	api_error	d2f9a12054ad35e488278432be6bef89	2026-03-13 17:35:04.568679+00	2026-03-13 17:35:46.982421+00	JSON parse error: Unexpected character ('\\' (code 92)): was expecting double-quote to start field name	3	D:\\repo\\valutavalto-program	\N	\N	POST	f	\N	\N	ERROR	org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Unexpected character ('\\' (code 92)): was expecting double-quote to start field name\n\tat org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.readJavaType(AbstractJackson2HttpMessageConverter.java:406)\n\tat org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.read(AbstractJackson2HttpMessageConverter.java:354)\n\tat org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodArgumentResolver.readWithMessageConverters(AbstractMessageConverterMethodArgumentResolver.java:184)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.readWithMessageConverters(RequestResponseBodyMethodProcessor.java:161)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.resolveArgument(RequestResponseBodyMethodProcessor.java:135)\n\tat org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:122)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.getMethodArgumentValues(InvocableHandlerMethod.java:224)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:178)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:831)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)\n\tat org.	/api/v1/auth/login	\N	\N
ff684c0b-8d05-4352-9f99-4b2a937c4199	Valutaváltó ERP	\N	\N	2026-03-14 22:07:42.646996+00	f	\N	production	api_error	55660437e3c4c6111906d1afed03a427	2026-03-14 22:07:42.646992+00	2026-03-14 23:28:35.327078+00	Required request parameter 'code' for method parameter type String is not present	2	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.web.bind.MissingServletRequestParameterException: Required request parameter 'code' for method parameter type String is not present\n\tat org.springframework.web.method.annotation.RequestParamMethodArgumentResolver.handleMissingValueInternal(RequestParamMethodArgumentResolver.java:220)\n\tat org.springframework.web.method.annotation.RequestParamMethodArgumentResolver.handleMissingValue(RequestParamMethodArgumentResolver.java:196)\n\tat org.springframework.web.method.annotation.AbstractNamedValueMethodArgumentResolver.resolveArgument(AbstractNamedValueMethodArgumentResolver.java:126)\n\tat org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:122)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.getMethodArgumentValues(InvocableHandlerMethod.java:224)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:178)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:831)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.java:227)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:137)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:126)\n\tat org.springframework.security.web.access.ExceptionTranslationFilter.doFilter(ExceptionTranslationFilter.java:120)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(Obs	/api/v1/email/accounts/callback	\N	\N
2348ce5b-34ac-47a9-a608-a865a37ad081	Valutaváltó ERP	\N	\N	2026-03-18 08:20:46.584541+00	f	\N	production	api_error	e907facd1f5b7ea4ff94f8705da034f7	2026-03-18 08:20:46.584541+00	2026-03-18 08:20:49.241644+00	Required request parameter 'branchId' for method parameter type UUID is present but converted to null	4	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.web.bind.MissingServletRequestParameterException: Required request parameter 'branchId' for method parameter type UUID is present but converted to null\n\tat org.springframework.web.method.annotation.RequestParamMethodArgumentResolver.handleMissingValueInternal(RequestParamMethodArgumentResolver.java:220)\n\tat org.springframework.web.method.annotation.RequestParamMethodArgumentResolver.handleMissingValueAfterConversion(RequestParamMethodArgumentResolver.java:203)\n\tat org.springframework.web.method.annotation.AbstractNamedValueMethodArgumentResolver.resolveArgument(AbstractNamedValueMethodArgumentResolver.java:145)\n\tat org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:122)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.getMethodArgumentValues(InvocableHandlerMethod.java:224)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:178)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:831)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:101)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.config.RateLimitFilter.doFilterInternal(RateLimitFilter.java:59)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.Observ	/api/v1/decade-reports	\N	\N
d4753ee0-dabb-4a50-842a-3b24ec5fc7a2	Valutaváltó ERP	\N	\N	2026-03-17 15:34:41.085159+00	f	\N	production	api_error	dbab082bde77f4121ee3637d8ed47730	2026-03-17 15:34:41.085152+00	2026-03-18 08:24:49.530556+00	Could not write JSON: could not initialize proxy [hu.puzzleir.valuta.entity.Company#17015396-a878-4677-ab8e-05f2f7a8ee6c] - no Session	32	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.http.converter.HttpMessageNotWritableException: Could not write JSON: could not initialize proxy [hu.puzzleir.valuta.entity.Company#17015396-a878-4677-ab8e-05f2f7a8ee6c] - no Session\n\tat org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.writeInternal(AbstractJackson2HttpMessageConverter.java:492)\n\tat org.springframework.http.converter.AbstractGenericHttpMessageConverter.write(AbstractGenericHttpMessageConverter.java:114)\n\tat org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodProcessor.writeWithMessageConverters(AbstractMessageConverterMethodProcessor.java:297)\n\tat org.springframework.web.servlet.mvc.method.annotation.HttpEntityMethodProcessor.handleReturnValue(HttpEntityMethodProcessor.java:245)\n\tat org.springframework.web.method.support.HandlerMethodReturnValueHandlerComposite.handleReturnValue(HandlerMethodReturnValueHandlerComposite.java:78)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:136)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:831)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:101)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat hu.puzzleir.valuta.config.RateLimitFilter.doFilterInternal(RateLimitFilter.java:59)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:479)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:340)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:82)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$VirtualFilterChain.doFilter(ObservationFilterChainDecorator.java:128)\n\tat org.springframework.security.web.access.intercept.AuthorizationFilter.doFilter(AuthorizationFilter.java:100)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.wrapFilter(ObservationFilterChainDecorator.java:240)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$ObservationFilter.doFilter(ObservationFilterChainDecorator.jav	/api/v1/cash-balances/summary	\N	\N
110b6cc7-a641-48bf-b110-a4b8a212b753	Valutaváltó ERP	\N	\N	2026-03-18 17:23:55.366786+00	f	\N	production	api_error	d2fcd3353bdde364bd29cc42db82afa7	2026-03-18 17:23:55.36678+00	2026-03-19 02:14:43.871649+00	Could not commit JPA transaction	15	D:\\repo\\valutavalto-program	\N	\N	POST	f	\N	\N	ERROR	org.springframework.transaction.TransactionSystemException: Could not commit JPA transaction\n\tat org.springframework.orm.jpa.JpaTransactionManager.doCommit(JpaTransactionManager.java:571)\n\tat org.springframework.transaction.support.AbstractPlatformTransactionManager.processCommit(AbstractPlatformTransactionManager.java:794)\n\tat org.springframework.transaction.support.AbstractPlatformTransactionManager.commit(AbstractPlatformTransactionManager.java:757)\n\tat org.springframework.transaction.interceptor.TransactionAspectSupport.commitTransactionAfterReturning(TransactionAspectSupport.java:676)\n\tat org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:426)\n\tat org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:119)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:768)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:720)\n\tat hu.puzzleir.valuta.service.DailySessionService$$SpringCGLIB$$0.openDay(<generated>)\n\tat hu.puzzleir.valuta.controller.DailySessionController.openDay(DailySessionController.java:39)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:354)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:768)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.invoke(AuthorizationManagerBeforeMethodInterceptor.java:198)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$CglibMethodInvocation.proceed(CglibAopProxy.java:768)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:720)\n\tat hu.puzzleir.valuta.controller.DailySessionController$$SpringCGLIB$$0.openDay(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:255)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:188)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:831)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:206)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:150)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:175)\n\tat org.apache.cata	/api/v1/daily-sessions/open	\N	\N
47563eae-a1ca-4b79-9040-2c6439bd5d50	Valutaváltó ERP	\N	\N	2026-03-19 06:17:48.296165+00	f	\N	production	api_error	8931e61727762590e08a27b8e6f33ae2	2026-03-19 06:17:48.296162+00	2026-03-19 06:17:50.288808+00	500 Internal Server Error on GET request for "https://oauth2.googleapis.com/tokeninfo": "{<EOL>  "error": {<EOL>    "code": 500,<EOL>    "message": "Internal error encountered.",<EOL>    "status": "INTERNAL"<EOL>  }<EOL>}<EOL>"	2	D:\\repo\\valutavalto-program	\N	\N	POST	f	\N	\N	ERROR	org.springframework.web.client.HttpServerErrorException$InternalServerError: 500 Internal Server Error on GET request for "https://oauth2.googleapis.com/tokeninfo": "{<EOL>  "error": {<EOL>    "code": 500,<EOL>    "message": "Internal error encountered.",<EOL>    "status": "INTERNAL"<EOL>  }<EOL>}<EOL>"\n\tat org.springframework.web.client.HttpServerErrorException.create(HttpServerErrorException.java:102)\n\tat org.springframework.web.client.DefaultResponseErrorHandler.handleError(DefaultResponseErrorHandler.java:189)\n\tat org.springframework.web.client.DefaultResponseErrorHandler.handleError(DefaultResponseErrorHandler.java:147)\n\tat org.springframework.web.client.RestTemplate.handleResponse(RestTemplate.java:953)\n\tat org.springframework.web.client.RestTemplate.doExecute(RestTemplate.java:902)\n\tat org.springframework.web.client.RestTemplate.execute(RestTemplate.java:801)\n\tat org.springframework.web.client.RestTemplate.getForObject(RestTemplate.java:415)\n\tat hu.puzzleir.valuta.controller.GoogleAuthController.fetchTokenInfo(GoogleAuthController.java:129)\n\tat hu.puzzleir.valuta.controller.GoogleAuthController.googleLogin(GoogleAuthController.java:59)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.proceed(AuthorizationManagerBeforeMethodInterceptor.java:268)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.attemptAuthorization(AuthorizationManagerBeforeMethodInterceptor.java:263)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.invoke(AuthorizationManagerBeforeMethodInterceptor.java:196)\n\tat org.springframework.security.config.annotation.method.configuration.DeferringMethodInterceptor.invoke(DeferringMethodInterceptor.java:44)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.controller.GoogleAuthController$$SpringCGLIB$$0.googleLogin(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:258)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:191)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:991)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:896)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:101)\n\tat org.apache.catalina.core.ApplicationFilterCh	/api/v1/auth/google-login	\N	\N
b43c2e3a-d585-46e7-ae81-f453435ec5c9	Valutaváltó ERP	\N	\N	2026-03-23 10:47:40.821882+00	f	\N	production	api_error	c25700c32ccb4c464ece0f4e58dd1fe4	2026-03-23 10:47:40.821875+00	2026-03-23 14:29:11.157288+00	JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 left join company c1_0 on c1_0.id=rw1_0.company_id where c1_0.id=? and rw1_0.active] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]	8	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.dao.InvalidDataAccessResourceUsageException: JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 left join company c1_0 on c1_0.id=rw1_0.company_id where c1_0.id=? and rw1_0.active] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:281)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:256)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.translateExceptionIfPossible(HibernateJpaDialect.java:241)\n\tat org.springframework.orm.jpa.AbstractEntityManagerFactoryBean.translateExceptionIfPossible(AbstractEntityManagerFactoryBean.java:560)\n\tat org.springframework.dao.support.ChainedPersistenceExceptionTranslator.translateExceptionIfPossible(ChainedPersistenceExceptionTranslator.java:61)\n\tat org.springframework.dao.support.DataAccessUtils.translateIfNecessary(DataAccessUtils.java:343)\n\tat org.springframework.dao.support.PersistenceExceptionTranslationInterceptor.invoke(PersistenceExceptionTranslationInterceptor.java:160)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.data.jpa.repository.support.CrudMethodMetadataPostProcessor$CrudMethodMetadataPopulatingMethodInterceptor.invoke(CrudMethodMetadataPostProcessor.java:136)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:223)\n\tat jdk.proxy2/jdk.proxy2.$Proxy315.findByCompanyIdAndActiveTrue(Unknown Source)\n\tat hu.puzzleir.valuta.service.RateCreationService.getWorkgroupDetails(RateCreationService.java:239)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:380)\n\tat org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:119)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.service.RateCreationService$$SpringCGLIB$$0.getWorkgroupDetails(<generated>)\n\tat hu.puzzleir.valuta.controller.RateCreationController.getWorkgroupDetails(RateCreationController.java:92)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.proceed(AuthorizationManagerBeforeMethodInterceptor.java:268)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.attemptAuthorization(AuthorizationManagerBeforeMethodInterceptor.java:263)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.invoke(AuthorizationManagerBeforeMethodInterceptor.java:196)\n\tat org.springframework.security.config.annotation.method.configuration.DeferringMethodInterceptor.invoke(DeferringMethodInterceptor.java:44)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.controller.RateCreationController$$SpringCGLIB$$0.getWorkgroupDetails(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:258)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:191)\n\tat org.springframework.w	/api/v1/rate-creation/workgroups	\N	\N
1ad064d9-5096-422d-806f-cd24720d70e2	Valutaváltó ERP	\N	\N	2026-03-23 17:19:36.977521+00	f	\N	production	api_error	b2a7d15c0084a5d30db9b984b38ac403	2026-03-23 17:19:36.977513+00	2026-03-23 17:19:36.977515+00	JSON parse error: Unexpected character ('\\' (code 92)): was expecting double-quote to start field name	1	D:\\repo\\valutavalto-program	\N	\N	POST	f	\N	\N	ERROR	org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Unexpected character ('\\' (code 92)): was expecting double-quote to start field name\n\tat org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.readJavaType(AbstractJackson2HttpMessageConverter.java:408)\n\tat org.springframework.http.converter.json.AbstractJackson2HttpMessageConverter.read(AbstractJackson2HttpMessageConverter.java:356)\n\tat org.springframework.web.servlet.mvc.method.annotation.AbstractMessageConverterMethodArgumentResolver.readWithMessageConverters(AbstractMessageConverterMethodArgumentResolver.java:204)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.readWithMessageConverters(RequestResponseBodyMethodProcessor.java:176)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestResponseBodyMethodProcessor.resolveArgument(RequestResponseBodyMethodProcessor.java:150)\n\tat org.springframework.web.method.support.HandlerMethodArgumentResolverComposite.resolveArgument(HandlerMethodArgumentResolverComposite.java:122)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.getMethodArgumentValues(InvocableHandlerMethod.java:227)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:181)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:991)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:896)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doPost(FrameworkServlet.java:914)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:590)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:101)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat hu.puzzleir.valuta.config.RateLimitFilter.doFilterInternal(RateLimitFilter.java:120)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:490)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$AroundFilterObservation$SimpleAroundFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:351)\n\tat org.springframework.security.web.ObservationFilterChainDecorator.lambda$wrapSecured$0(ObservationFilterChainDecorator.java:83)\n\tat org.springfr	/api/v1/auth/login	\N	\N
5274c1b1-e347-488e-847f-60ecace2d3cf	Valutaváltó ERP	\N	\N	2026-03-23 17:41:55.896837+00	f	\N	production	api_error	0cc3d7da66d1b672b6e4b8ee06a064ad	2026-03-23 17:41:55.896826+00	2026-03-23 18:04:26.980755+00	JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 left join company c1_0 on c1_0.id=rw1_0.company_id where c1_0.id=? and rw1_0.active] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]	6	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.dao.InvalidDataAccessResourceUsageException: JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 left join company c1_0 on c1_0.id=rw1_0.company_id where c1_0.id=? and rw1_0.active] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:281)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:256)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.translateExceptionIfPossible(HibernateJpaDialect.java:241)\n\tat org.springframework.orm.jpa.AbstractEntityManagerFactoryBean.translateExceptionIfPossible(AbstractEntityManagerFactoryBean.java:560)\n\tat org.springframework.dao.support.ChainedPersistenceExceptionTranslator.translateExceptionIfPossible(ChainedPersistenceExceptionTranslator.java:61)\n\tat org.springframework.dao.support.DataAccessUtils.translateIfNecessary(DataAccessUtils.java:343)\n\tat org.springframework.dao.support.PersistenceExceptionTranslationInterceptor.invoke(PersistenceExceptionTranslationInterceptor.java:160)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.data.jpa.repository.support.CrudMethodMetadataPostProcessor$CrudMethodMetadataPopulatingMethodInterceptor.invoke(CrudMethodMetadataPostProcessor.java:136)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:223)\n\tat jdk.proxy2/jdk.proxy2.$Proxy315.findByCompanyIdAndActiveTrue(Unknown Source)\n\tat hu.puzzleir.valuta.service.RateCreationService.getWorkgroupDetails(RateCreationService.java:239)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:380)\n\tat org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:119)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.service.RateCreationService$$SpringCGLIB$$0.getWorkgroupDetails(<generated>)\n\tat hu.puzzleir.valuta.controller.RateCreationController.getWorkgroupDetails(RateCreationController.java:108)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.proceed(AuthorizationManagerBeforeMethodInterceptor.java:268)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.attemptAuthorization(AuthorizationManagerBeforeMethodInterceptor.java:263)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.invoke(AuthorizationManagerBeforeMethodInterceptor.java:196)\n\tat org.springframework.security.config.annotation.method.configuration.DeferringMethodInterceptor.invoke(DeferringMethodInterceptor.java:44)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.controller.RateCreationController$$SpringCGLIB$$0.getWorkgroupDetails(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:258)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:191)\n\tat org.springframework.	/api/v1/rate-creation/workgroups	\N	\N
a07515b7-6ce4-4bcf-b849-2c2da42428b7	Valutaváltó ERP	\N	\N	2026-03-23 17:50:10.738626+00	f	\N	production	api_error	cea62f045155e852ba9ac3823c02ad73	2026-03-23 17:50:10.738626+00	2026-03-23 17:50:10.738626+00	JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 where rw1_0.id=?] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]	1	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.springframework.dao.InvalidDataAccessResourceUsageException: JDBC exception executing SQL [select rw1_0.id,rw1_0.active,rw1_0.code,rw1_0.company_id,rw1_0.created_at,rw1_0.legacy_group_number,rw1_0.limit1_boundary,rw1_0.limit2_boundary,rw1_0.limit3_boundary,rw1_0.name from rate_workgroup rw1_0 where rw1_0.id=?] [ERROR: column rw1_0.limit1_boundary does not exist\n  Position: 101] [n/a]; SQL [n/a]\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:281)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.convertHibernateAccessException(HibernateJpaDialect.java:256)\n\tat org.springframework.orm.jpa.vendor.HibernateJpaDialect.translateExceptionIfPossible(HibernateJpaDialect.java:241)\n\tat org.springframework.orm.jpa.AbstractEntityManagerFactoryBean.translateExceptionIfPossible(AbstractEntityManagerFactoryBean.java:560)\n\tat org.springframework.dao.support.ChainedPersistenceExceptionTranslator.translateExceptionIfPossible(ChainedPersistenceExceptionTranslator.java:61)\n\tat org.springframework.dao.support.DataAccessUtils.translateIfNecessary(DataAccessUtils.java:343)\n\tat org.springframework.dao.support.PersistenceExceptionTranslationInterceptor.invoke(PersistenceExceptionTranslationInterceptor.java:160)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.data.jpa.repository.support.CrudMethodMetadataPostProcessor$CrudMethodMetadataPopulatingMethodInterceptor.invoke(CrudMethodMetadataPostProcessor.java:165)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:223)\n\tat jdk.proxy2/jdk.proxy2.$Proxy315.findById(Unknown Source)\n\tat hu.puzzleir.valuta.service.RateCreationService.getAllBranchesForWorkgroup(RateCreationService.java:495)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:380)\n\tat org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:119)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.service.RateCreationService$$SpringCGLIB$$0.getAllBranchesForWorkgroup(<generated>)\n\tat hu.puzzleir.valuta.controller.RateCreationController.getBranches(RateCreationController.java:131)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.invokeJoinpoint(ReflectiveMethodInvocation.java:196)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:163)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.proceed(AuthorizationManagerBeforeMethodInterceptor.java:268)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.attemptAuthorization(AuthorizationManagerBeforeMethodInterceptor.java:263)\n\tat org.springframework.security.authorization.method.AuthorizationManagerBeforeMethodInterceptor.invoke(AuthorizationManagerBeforeMethodInterceptor.java:196)\n\tat org.springframework.security.config.annotation.method.configuration.DeferringMethodInterceptor.invoke(DeferringMethodInterceptor.java:44)\n\tat org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:184)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:728)\n\tat hu.puzzleir.valuta.controller.RateCreationController$$SpringCGLIB$$0.getBranches(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:258)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:191)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletIn	/api/v1/rate-creation/branches	\N	\N
19819fb9-44a4-4a9d-8d8a-0208a8781d51	Valutaváltó ERP	\N	\N	2026-03-23 10:52:57.881167+00	f	\N	production	api_error	6cf7d0a6b9ec6fb7eadfae01ac381864	2026-03-23 10:52:57.881166+00	2026-03-23 17:52:24.445066+00	Could not initialize proxy [hu.puzzleir.valuta.entity.Branch#dd29ef03-c7cc-4fb8-9106-045991627a85] - no session	29	D:\\repo\\valutavalto-program	\N	\N	GET	f	\N	\N	ERROR	org.hibernate.LazyInitializationException: Could not initialize proxy [hu.puzzleir.valuta.entity.Branch#dd29ef03-c7cc-4fb8-9106-045991627a85] - no session\n\tat org.hibernate.proxy.AbstractLazyInitializer.initialize(AbstractLazyInitializer.java:174)\n\tat org.hibernate.proxy.AbstractLazyInitializer.getImplementation(AbstractLazyInitializer.java:328)\n\tat org.hibernate.proxy.pojo.bytebuddy.ByteBuddyInterceptor.intercept(ByteBuddyInterceptor.java:44)\n\tat org.hibernate.proxy.ProxyConfiguration$InterceptorDispatcher.intercept(ProxyConfiguration.java:102)\n\tat hu.puzzleir.valuta.entity.Branch$HibernateProxy.getName(Unknown Source)\n\tat hu.puzzleir.valuta.mapper.DailySessionMapper.toDto(DailySessionMapper.java:28)\n\tat hu.puzzleir.valuta.controller.DailySessionController.getCurrentSession(DailySessionController.java:78)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.aop.support.AopUtils.invokeJoinpointUsingReflection(AopUtils.java:360)\n\tat org.springframework.aop.framework.CglibAopProxy$DynamicAdvisedInterceptor.intercept(CglibAopProxy.java:724)\n\tat hu.puzzleir.valuta.controller.DailySessionController$$SpringCGLIB$$0.getCurrentSession(<generated>)\n\tat java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)\n\tat java.base/java.lang.reflect.Method.invoke(Unknown Source)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:258)\n\tat org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:191)\n\tat org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:991)\n\tat org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.handleInternal(RequestMappingHandlerAdapter.java:896)\n\tat org.springframework.web.servlet.mvc.method.AbstractHandlerMethodAdapter.handle(AbstractHandlerMethodAdapter.java:87)\n\tat org.springframework.web.servlet.DispatcherServlet.doDispatch(DispatcherServlet.java:1089)\n\tat org.springframework.web.servlet.DispatcherServlet.doService(DispatcherServlet.java:979)\n\tat org.springframework.web.servlet.FrameworkServlet.processRequest(FrameworkServlet.java:1014)\n\tat org.springframework.web.servlet.FrameworkServlet.doGet(FrameworkServlet.java:903)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:564)\n\tat org.springframework.web.servlet.FrameworkServlet.service(FrameworkServlet.java:885)\n\tat jakarta.servlet.http.HttpServlet.service(HttpServlet.java:658)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:193)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:51)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:110)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:101)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat hu.puzzleir.valuta.errorlog.RequestIdFilter.doFilter(RequestIdFilter.java:23)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat hu.puzzleir.valuta.config.RateLimitFilter.doFilterInternal(RateLimitFilter.java:75)\n\tat org.springframework.web.filter.OncePerRequestFilter.doFilter(OncePerRequestFilter.java:116)\n\tat org.apache.catalina.core.ApplicationFilterChain.internalDoFilter(ApplicationFilterChain.java:162)\n\tat org.apache.catalina.core.ApplicationFilterChain.doFilter(ApplicationFilterChain.java:138)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.web.filter.CompositeFilter$VirtualFilterChain.doFilter(CompositeFilter.java:108)\n\tat org.springframework.security.web.FilterChainProxy.lambda$doFilterInternal$3(FilterChainProxy.java:231)\n\tat org.springframework.security.web.ObservationFilterChainDecorator$FilterObservation$SimpleFilterObservation.lambda$wrap$1(ObservationFilterChainDecorator.java:490)\n\tat org.springfram	/api/v1/daily-sessions/current	\N	\N
\.


--
-- Data for Name: evening_closing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evening_closing (id, branch_id, closing_date, company_id, confirmed_at, created_at, inventory_snapshot, package_data, sent_at, status, total_buy_huf, total_sell_huf, transaction_count, updated_at) FROM stdin;
\.


--
-- Data for Name: evening_sync_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.evening_sync_log (id, attempt_count, branch_id, completed_at, created_at, error_message, last_attempt_at, package_checksum, status, sync_date) FROM stdin;
\.


--
-- Data for Name: exchange_rate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exchange_rate (id, is_active, base_buy_rate, base_sell_rate, created_at, created_by, limit1_amount, limit1_buy_rate, limit1_sell_rate, limit2_amount, limit2_buy_rate, limit2_sell_rate, limit3_amount, limit3_buy_rate, limit3_sell_rate, official_rate, valid_date, valid_time, version, branch_id, company_id, currency_id) FROM stdin;
15	t	4.0598	4.4872	2026-03-16 12:51:14.485577	SYSTEM	50000.00	4.0900	4.4570	200000.00	4.1200	4.4270	\N	\N	\N	4.2735	2026-03-16	12:51:14.485577	0	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	18
16	t	7.3643	8.1395	2026-03-16 12:51:14.485577	SYSTEM	10000.00	7.4200	8.0840	50000.00	7.4750	8.0280	\N	\N	\N	7.7519	2026-03-16	12:51:14.485577	0	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	19
1	t	386.2800	398.0400	2026-03-16 12:51:14.485577	SYSTEM	1000.00	387.5000	396.8000	5000.00	388.7000	395.6000	\N	\N	\N	391.4800	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
18	t	386.2800	398.0400	2026-03-16 12:51:15.228821	SYSTEM	1000.00	387.5000	396.8000	5000.00	388.7000	395.6000	\N	\N	\N	391.4800	2026-03-16	12:51:15.228	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
21	t	386.2800	398.0400	2026-03-16 12:51:15.228821	SYSTEM	1000.00	387.5000	396.8000	5000.00	388.7000	395.6000	\N	\N	\N	391.4800	2026-03-16	12:51:15.228	1	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
2	t	335.6200	349.3100	2026-03-16 12:51:14.485577	SYSTEM	1000.00	336.9000	347.9500	5000.00	338.2000	346.6000	\N	\N	\N	341.1293	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	5
19	t	335.6200	349.3100	2026-03-16 12:51:15.228821	SYSTEM	1000.00	336.9000	347.9500	5000.00	338.2000	346.6000	\N	\N	\N	341.1293	2026-03-16	12:51:15.228	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	5
22	t	335.6200	349.3100	2026-03-16 12:51:15.228821	SYSTEM	1000.00	336.9000	347.9500	5000.00	338.2000	346.6000	\N	\N	\N	341.1293	2026-03-16	12:51:15.228	1	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	5
11	t	2.0557	2.2271	2026-03-16 12:51:14.485577	SYSTEM	100000.00	2.0700	2.2130	500000.00	2.0850	2.1980	\N	\N	\N	2.1410	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	14
5	t	15.4100	16.6900	2026-03-16 12:51:14.485577	SYSTEM	10000.00	15.5500	16.5500	50000.00	15.6500	16.4500	\N	\N	\N	16.0200	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	8
10	t	51.3300	53.4300	2026-03-16 12:51:14.485577	SYSTEM	5000.00	51.5500	53.2000	20000.00	51.8000	52.9500	\N	\N	\N	52.3887	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	13
3	t	443.1800	465.9100	2026-03-16 12:51:14.485577	SYSTEM	500.00	445.0000	464.0000	2000.00	447.0000	462.0000	\N	\N	\N	452.5623	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	6
20	t	443.1800	465.9100	2026-03-16 12:51:15.228821	SYSTEM	500.00	445.0000	464.0000	2000.00	447.0000	462.0000	\N	\N	\N	452.5623	2026-03-16	12:51:15.228	1	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	6
23	t	443.1800	465.9100	2026-03-16 12:51:15.228821	SYSTEM	500.00	445.0000	464.0000	2000.00	447.0000	462.0000	\N	\N	\N	452.5623	2026-03-16	12:51:15.228	1	8129b5a1-25f3-46a0-a02a-02f1f34ddd34	17015396-a878-4677-ab8e-05f2f7a8ee6c	6
6	t	88.0700	95.4100	2026-03-16 12:51:14.485577	SYSTEM	1000.00	88.9000	94.5500	5000.00	89.7000	93.7000	\N	\N	\N	91.7352	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	9
7	t	73.8500	80.0000	2026-03-16 12:51:14.485577	SYSTEM	1000.00	74.5000	79.3500	5000.00	75.1500	78.7000	\N	\N	\N	76.8406	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	10
8	t	34.9400	37.8600	2026-03-16 12:51:14.485577	SYSTEM	5000.00	35.2000	37.6000	20000.00	35.4500	37.3500	\N	\N	\N	36.4015	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	11
4	t	422.0800	443.7300	2026-03-16 12:51:14.485577	SYSTEM	500.00	423.5000	442.2000	2000.00	425.0000	440.6000	\N	\N	\N	433.3407	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	7
9	t	33.6800	36.4900	2026-03-16 12:51:14.485577	SYSTEM	5000.00	33.9500	36.2000	20000.00	34.2000	35.9500	\N	\N	\N	35.0820	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	12
17	t	7.3331	8.1050	2026-03-16 12:51:14.485577	SYSTEM	10000.00	7.3880	8.0500	50000.00	7.4430	7.9950	\N	\N	\N	7.7196	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	20
13	t	234.3700	246.3900	2026-03-16 12:51:14.485577	SYSTEM	500.00	235.3000	245.4500	2000.00	236.2500	244.5000	\N	\N	\N	240.2750	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	16
12	t	243.7500	256.2500	2026-03-16 12:51:14.485577	SYSTEM	500.00	244.8000	255.2000	2000.00	245.9000	254.1000	\N	\N	\N	248.9381	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	15
14	t	46.8000	51.7200	2026-03-16 12:51:14.485577	SYSTEM	5000.00	47.2000	51.3000	20000.00	47.6000	50.9000	\N	\N	\N	49.4636	2026-03-16	12:51:14.485	1	\N	17015396-a878-4677-ab8e-05f2f7a8ee6c	17
\.


--
-- Data for Name: exchange_rate_display; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exchange_rate_display (id, created_at, currency_ids, display_name, is_active, refresh_interval, updated_at) FROM stdin;
\.


--
-- Data for Name: exchange_rate_source; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.exchange_rate_source (id, is_active, created_at, error_count, last_error, last_error_at, last_polled_at, last_success_at, polling_interval_minutes, source_name, source_url, success_count, updated_at) FROM stdin;
\.


--
-- Data for Name: fee_discount; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fee_discount (id, code, created_at, discount_type, discount_value, is_active, min_transaction_amount, name, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: fee_rate; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fee_rate (id, branch_id, created_at, currency_id, fee_type_id, fixed_amount, is_active, max_amount, min_amount, rate, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: fee_type; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.fee_type (id, calculation_method, code, created_at, description, is_active, name, updated_at) FROM stdin;
\.


--
-- Data for Name: feor_code; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.feor_code (id, code, title) FROM stdin;
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	67	<< Flyway Baseline >>	BASELINE	<< Flyway Baseline >>	\N	zltn	2026-03-13 07:59:10.624401	0	t
2	68	worker email	SQL	V68__worker_email.sql	-1362273569	zltn	2026-03-13 15:09:21.444184	31	t
3	69	seed tisza sarok	SQL	V69__seed_tisza_sarok.sql	1559552139	zltn	2026-03-13 16:56:22.36108	49	t
4	70	seed currencies	SQL	V70__seed_currencies.sql	-1590315014	zltn	2026-03-13 17:16:32.611781	64	t
6	72	sync outbox inbox	SQL	V72__sync_outbox_inbox.sql	2049331579	zltn	2026-03-16 08:33:08.614822	74	t
7	73	document company id	SQL	V73__document_company_id.sql	507251107	zltn	2026-03-16 08:33:08.738961	33	t
8	74	missing critical tables	SQL	V74__missing_critical_tables.sql	696443878	zltn	2026-03-16 08:33:08.828113	184	t
9	75	missing secondary tables	SQL	V75__missing_secondary_tables.sql	122269224	zltn	2026-03-16 08:33:09.07976	210	t
10	76	seed exchange rates	SQL	V76__seed_exchange_rates.sql	143575110	zltn	2026-03-16 12:51:14.391303	37	t
11	77	fix v4 fk type mismatches	SQL	V77__fix_v4_fk_type_mismatches.sql	1684313160	zltn	2026-03-16 12:51:14.591605	72	t
12	78	currency max deviation percent	SQL	V78__currency_max_deviation_percent.sql	-267696221	zltn	2026-03-16 12:51:14.717413	25	t
13	79	legacy parity gaps	SQL	V79__legacy_parity_gaps.sql	-315433544	zltn	2026-03-16 12:51:14.791193	33	t
14	80	critical missing indexes	SQL	V80__critical_missing_indexes.sql	-469439943	zltn	2026-03-16 12:51:14.869173	57	t
15	81	vault ertektar tables	SQL	V81__vault_ertektar_tables.sql	1578757533	zltn	2026-03-16 12:51:14.974369	108	t
16	82	decade profit lines	SQL	V82__decade_profit_lines.sql	1645481294	zltn	2026-03-16 12:51:15.134297	36	t
17	83	seed cash registers and stocks	SQL	V83__seed_cash_registers_and_stocks.sql	-1229674668	zltn	2026-03-16 12:51:15.2118	44	t
18	84	handling fee decade and forint control	SQL	V84__handling_fee_decade_and_forint_control.sql	1605561466	zltn	2026-03-16 12:51:15.301142	47	t
19	85	pos terminal otp fields	SQL	V85__pos_terminal_otp_fields.sql	173797429	zltn	2026-03-16 12:51:15.3916	21	t
20	86	fix exchange rate version null	SQL	V86__fix_exchange_rate_version_null.sql	955053910	zltn	2026-03-16 12:51:15.453657	23	t
21	87	vault bank transfer receipt correction	SQL	V87__vault_bank_transfer_receipt_correction.sql	1964448573	zltn	2026-03-16 12:51:15.519785	170	t
22	88	circular per worker ack and archive	SQL	V88__circular_per_worker_ack_and_archive.sql	-829642426	zltn	2026-03-16 12:51:15.732757	95	t
23	89	monthly transaction archive	SQL	V89__monthly_transaction_archive.sql	1656029217	zltn	2026-03-16 12:51:15.869515	36	t
24	90	customer high risk flag	SQL	V90__customer_high_risk_flag.sql	-1613981289	zltn	2026-03-16 12:51:15.946237	23	t
25	91	wu transaction status enum and constraints	SQL	V91__wu_transaction_status_enum_and_constraints.sql	1181951809	zltn	2026-03-16 12:51:16.008915	42	t
26	92	notification idempotency fields	SQL	V92__notification_idempotency_fields.sql	-553294449	zltn	2026-03-16 12:51:16.092761	26	t
27	93	mnb report retry status columns	SQL	V93__mnb_report_retry_status_columns.sql	1154831357	zltn	2026-03-17 14:05:12.373	53	t
28	94	partial refund columns	SQL	V94__partial_refund_columns.sql	-866460978	zltn	2026-03-17 14:05:12.523386	27	t
29	95	branch region code	SQL	V95__branch_region_code.sql	395221720	zltn	2026-03-17 14:05:12.593549	29	t
30	96	wu company id	SQL	V96__wu_company_id.sql	-1246656457	zltn	2026-03-17 14:05:12.671769	97	t
31	97	seal tracking	SQL	V97__seal_tracking.sql	476837977	zltn	2026-03-17 14:05:12.83103	58	t
32	98	led display config	SQL	V98__led_display_config.sql	731909603	zltn	2026-03-17 14:05:12.934565	48	t
33	99	wu customer unique constraint	SQL	V99__wu_customer_unique_constraint.sql	930176202	zltn	2026-03-17 14:05:13.046213	26	t
5	71	exchange rate master	SQL	V71__fix_rate_template_currency_fk.sql	941035304	zltn	2026-03-16 08:33:08.238743	257	t
34	100	rate management multi tenant and limits	SQL	V100__rate_management_multi_tenant_and_limits.sql	-1249370580	zltn	2026-03-18 20:27:12.421556	252	t
35	101	worker google email setup	SQL	V101__worker_google_email_setup.sql	1784296270	zltn	2026-03-18 20:46:20.880238	39	t
36	102	token blacklist	SQL	V102__token_blacklist.sql	-275629084	zltn	2026-03-18 20:46:21.056175	53	t
37	103	fix cash balance version null	SQL	V103__fix_cash_balance_version_null.sql	-1402312127	zltn	2026-03-19 04:23:48.797544	31	t
38	104	daily checklist	SQL	V104__daily_checklist.sql	-935403932	zltn	2026-03-19 22:05:08.540082	75	t
39	105	denomination category	SQL	V105__denomination_category.sql	472792579	zltn	2026-03-19 22:05:08.76642	58	t
40	106	transfer direction	SQL	V106__transfer_direction.sql	193531437	zltn	2026-03-19 22:05:08.882495	34	t
41	107	darius daily report	SQL	V107__darius_daily_report.sql	-1008828257	zltn	2026-03-21 07:28:14.156505	67	t
43	110	auth master data fallback seed	SQL	V110__auth_master_data_fallback_seed.sql	-1231713469	zltn	2026-03-23 15:19:16.295652	210	t
44	111	ensure login accounts borsi kosa	SQL	V111__ensure_login_accounts_borsi_kosa.sql	112292033	zltn	2026-03-23 15:19:16.66241	30	t
42	108	commission rule company id uuid	SQL	V108__camera_hash_chain_and_export.sql	-714271883	zltn	2026-03-21 07:28:14.416935	69	t
45	112	rate workgroup limit boundaries and defaults	SQL	V112__rate_workgroup_limit_boundaries_and_defaults.sql	2058477033	zltn	2026-03-23 18:24:54.441289	100	t
\.


--
-- Data for Name: ftp_sync_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ftp_sync_log (id, completed_at, direction, error_message, file_name, file_size_bytes, started_at, status, branch_id) FROM stdin;
\.


--
-- Data for Name: handling_fee_bracket; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.handling_fee_bracket (id, active, bracket_order, fee_amount, upper_limit, company_id) FROM stdin;
\.


--
-- Data for Name: handling_fee_decade_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.handling_fee_decade_report (id, branch_id, year, decade, period_start, period_end, opening_balance, total_buy_fee, total_sell_fee, total_card_fee, total_cash_fee, closing_balance, first_sequence_number, last_sequence_number, buy_count, sell_count, total_count, status, printed, closed_at, closed_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: handling_fee_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.handling_fee_transaction (id, amount, created_at, discount_percent, discount_reason, fee_type, net_fee, transaction_id, worker_commission_share) FROM stdin;
\.


--
-- Data for Name: handover_sheet; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.handover_sheet (id, amounts, created_at, created_by_id, from_cash_desk_id, notes, sheet_number, status, to_cash_desk_id, transfer_date) FROM stdin;
\.


--
-- Data for Name: hrk_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.hrk_transaction (id, amount, bank_account_number, branch_id, company_id, completed_at, created_at, currency_code, huf_amount, note, reference, status, type, worker_id) FROM stdin;
\.


--
-- Data for Name: initial_fee_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.initial_fee_config (id, active, daily_custom_fee_limit, daily_discount_limit, fee_amount, fee_name, max_fee_amount, min_transaction_amount, company_id) FROM stdin;
\.


--
-- Data for Name: inventory_movement; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_movement (id, amount, approved_at, created_at, huf_value, movement_date, movement_time, movement_type, notes, received_at, reference_number, status, approved_by_id, currency_id, from_branch_id, initiated_by_id, received_by_id, to_branch_id) FROM stdin;
\.


--
-- Data for Name: inventory_regeneration; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_regeneration (id, corrected_count, discrepancy_count, regenerated_at, result_data, branch_id, regenerated_by) FROM stdin;
\.


--
-- Data for Name: inventory_summary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventory_summary (id, bank_deposit_total, bank_withdraw_total, created_at, current_stock, daily_buy_total, daily_fee_total, daily_sell_total, last_updated, summary_date, branch_id, currency_id) FROM stdin;
\.


--
-- Data for Name: led_display; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.led_display (id, content, created_at, display_type, last_updated, branch_id) FROM stdin;
\.


--
-- Data for Name: led_display_config; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.led_display_config (id, connection_string, created_at, display_type, displayed_currencies, is_active, last_updated_at, refresh_interval_seconds, branch_id, serial_display_type, com_ports, currencies, show_bank_card, speed_command, speed, end_markers, decimal_separator, custom_text, display_ids, updated_at) FROM stdin;
\.


--
-- Data for Name: license; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.license (id, activated_at, company_id, created_at, features, is_active, license_key, max_branches, max_workers, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: material_receipt; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_receipt (id, company_id, receipt_number, receipt_type, vault_territory_id, branch_code, counterpart_name, note, status, created_at, finalized_at, created_by) FROM stdin;
\.


--
-- Data for Name: material_receipt_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.material_receipt_line (id, receipt_id, currency_code, amount, exchange_rate, huf_equivalent) FROM stdin;
\.


--
-- Data for Name: mnb_exchange_rate_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mnb_exchange_rate_cache (id, currency_code, fetched_at, official_rate, rate_date, unit) FROM stdin;
1	EUR	2026-03-16 12:51:14.485577	392.1600	2026-03-16	1
2	USD	2026-03-16 12:51:14.485577	342.4700	2026-03-16	1
3	GBP	2026-03-16 12:51:14.485577	454.5500	2026-03-16	1
4	CHF	2026-03-16 12:51:14.485577	432.9000	2026-03-16	1
5	CZK	2026-03-16 12:51:14.485577	16.0500	2026-03-16	1
6	PLN	2026-03-16 12:51:14.485577	91.7400	2026-03-16	1
7	RON	2026-03-16 12:51:14.485577	76.9200	2026-03-16	1
8	SEK	2026-03-16 12:51:14.485577	36.4000	2026-03-16	1
9	NOK	2026-03-16 12:51:14.485577	35.0900	2026-03-16	1
10	DKK	2026-03-16 12:51:14.485577	52.3800	2026-03-16	1
11	JPY	2026-03-16 12:51:14.485577	2.1414	2026-03-16	1
12	CAD	2026-03-16 12:51:14.485577	250.0000	2026-03-16	1
13	AUD	2026-03-16 12:51:14.485577	240.3800	2026-03-16	1
14	CNY	2026-03-16 12:51:14.485577	49.2600	2026-03-16	1
15	RUB	2026-03-16 12:51:14.485577	4.2735	2026-03-16	1
16	UAH	2026-03-16 12:51:14.485577	7.7519	2026-03-16	1
17	TRY	2026-03-16 12:51:14.485577	7.7190	2026-03-16	1
\.


--
-- Data for Name: mnb_report; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mnb_report (id, accepted_at, created_at, rejection_reason, report_date, report_type, status, submitted_at, total_buy_huf, total_sell_huf, total_transactions, updated_at, xml_content, branch_id, retry_count, last_retry_at, mnb_reference_number, submission_error, acknowledged_at, rejected_at, rejection_reason_detail) FROM stdin;
\.


--
-- Data for Name: mnb_report_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mnb_report_line (id, buy_amount, buy_rate, currency_code, sell_amount, sell_rate, transaction_count, mnb_report_id) FROM stdin;
\.


--
-- Data for Name: monthly_closing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.monthly_closing (id, branch_id, buy_count, closed_by_id, closing_month, closing_year, company_id, created_at, reversal_count, sell_count, status, total_buy_huf, total_handling_fees, total_profit_huf, total_sell_huf, total_transaction_count, transaction_count, year_month) FROM stdin;
\.


--
-- Data for Name: monthly_closing_summary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.monthly_closing_summary (id, closed_at, created_at, currency_breakdown, total_buy_huf, total_handling_fee, total_sell_huf, transaction_count, year_month, branch_id, closed_by_worker_id) FROM stdin;
\.


--
-- Data for Name: nav_closing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.nav_closing (id, closed_at, closing_date, closing_type, created_at, handling_fee_total, nav_reference_number, status, total_expense, total_revenue, updated_at, vat_amount, branch_id, closed_by) FROM stdin;
\.


--
-- Data for Name: nav_closing_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.nav_closing_line (id, buy_amount, buy_huf, currency_code, handling_fee, sell_amount, sell_huf, transaction_count, nav_closing_id) FROM stdin;
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification (id, created_at, is_read, message, title, type, user_id, entity_type, entity_id, notification_type) FROM stdin;
\.


--
-- Data for Name: organization; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.organization (id, code, created_at, description, is_active, name, organization_type_did, parent_id, updated_at) FROM stdin;
\.


--
-- Data for Name: organizational_system_parameter; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.organizational_system_parameter (id, created_at, currency_id, is_active, organization_id, parameter_key, parameter_value, updated_at, valid_from, valid_to) FROM stdin;
\.


--
-- Data for Name: own_company; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.own_company (id, address, bank_account_number, created_at, email, iban, is_active, license_number, name, phone, registration_number, swift, tax_number, updated_at) FROM stdin;
\.


--
-- Data for Name: packaging_record; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.packaging_record (id, bundle_count, bundle_size, created_at, currency_code, denomination, notes, packaging_date, branch_id) FROM stdin;
\.


--
-- Data for Name: permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permission (id, code, created_at, description, is_active, is_system_permission, module, name) FROM stdin;
\.


--
-- Data for Name: police_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.police_request (id, completed_at, created_at, customer_name, date_range_from, date_range_to, document_number, request_date, request_number, requested_by, response_data, status, updated_at, created_by) FROM stdin;
\.


--
-- Data for Name: pos_terminal; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pos_terminal (id, branch_id, created_at, is_active, last_transaction_at, terminal_id, terminal_name, terminal_type, updated_at, ip_address, port) FROM stdin;
\.


--
-- Data for Name: print_template; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.print_template (id, company_id, content, created_at, is_default, name, template_type, updated_at) FROM stdin;
\.


--
-- Data for Name: profit_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profit_log (id, acquisition_cost, branch_id, created_at, currency_code, quantity, realized_profit, sale_price, transaction_id, transaction_type, company_id) FROM stdin;
\.


--
-- Data for Name: prohibited_company; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prohibited_company (id, company_name, created_at, is_active, list_source, list_type, reason, registration_number, tax_number, updated_at) FROM stdin;
\.


--
-- Data for Name: prohibited_person; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prohibited_person (id, created_at, date_of_birth, document_number, full_name, identity_number, is_active, list_source, list_type, nationality, passport_number, reason, updated_at) FROM stdin;
\.


--
-- Data for Name: rate_approval; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_approval (id, approved_at, created_at, currency_code, new_buy_rate, new_sell_rate, old_buy_rate, old_sell_rate, reason, requested_at, status, updated_at, approved_by, branch_id, requested_by) FROM stdin;
\.


--
-- Data for Name: rate_category; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_category (id, buy_rate, category, created_at, currency_code, max_amount, min_amount, sell_rate, updated_at, valid_from, valid_to, branch_id) FROM stdin;
\.


--
-- Data for Name: rate_discount; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_discount (id, active, buy_discount_percent, level, name, sell_discount_percent, workgroup_id, company_id) FROM stdin;
\.


--
-- Data for Name: rate_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_history (id, approved_by, branch_id, buy_rate, category, company_id, created_at, currency_code, effective_from, effective_to, mnb_rate, sell_rate, set_by, spread) FROM stdin;
\.


--
-- Data for Name: rate_publication; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_publication (id, affected_branches, notes, published_at, published_by, template_id, workgroup_id, company_id) FROM stdin;
\.


--
-- Data for Name: rate_template; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_template (id, approved_at, approved_by, base_buy_rate, base_sell_rate, buy_spread, created_at, created_by, currency_id, published_at, rounding_rule, sell_spread, status, workgroup_id, company_id, official_rate, limit1_amount, limit1_buy_rate, limit1_sell_rate, limit2_amount, limit2_buy_rate, limit2_sell_rate, limit3_amount, limit3_buy_rate, limit3_sell_rate) FROM stdin;
\.


--
-- Data for Name: rate_workgroup; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_workgroup (id, active, code, created_at, legacy_group_number, name, company_id, limit1_boundary, limit2_boundary, limit3_boundary) FROM stdin;
837e1146-1922-4d9f-b655-ac70a5a559ed	t	DEFAULT	2026-03-16 12:51:14.485577	0	Alapertelmezett	17015396-a878-4677-ab8e-05f2f7a8ee6c	50000.00	300000.00	1000000.00
\.


--
-- Data for Name: rate_workgroup_branch; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rate_workgroup_branch (workgroup_id, branch_id) FROM stdin;
837e1146-1922-4d9f-b655-ac70a5a559ed	dd29ef03-c7cc-4fb8-9106-045991627a85
837e1146-1922-4d9f-b655-ac70a5a559ed	8129b5a1-25f3-46a0-a02a-02f1f34ddd34
\.


--
-- Data for Name: receipt; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.receipt (id, content, created_at, is_printed, issue_date, nav_receipt_number, printed_at, receipt_number, receipt_type, transaction_id) FROM stdin;
\.


--
-- Data for Name: receipt_sequence; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.receipt_sequence (id, branch_id, last_buy_receipt, last_conversion_receipt, last_forint_transfer_in_receipt, last_forint_transfer_out_receipt, last_sell_receipt, last_transfer_in_receipt, last_transfer_out_receipt) FROM stdin;
\.


--
-- Data for Name: reservation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reservation (id, cancellation_reason, cancellation_receipt_number, cancelled_at, created_at, currency_code, deposit_amount, exchange_rate, expires_at, fulfilled_at, notes, receipt_number, refund_amount, reserved_amount, status, supervisor_approval, branch_id, company_id, customer_id, supervisor_worker_id, worker_id) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role (id, code, created_at, description, hierarchy_level, is_active, is_system_role, name, role_type) FROM stdin;
\.


--
-- Data for Name: role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_permission (role_id, permission_id) FROM stdin;
\.


--
-- Data for Name: rounding_rule; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rounding_rule (id, currency_code, large_rounding, large_threshold, precision_value, small_rounding, small_threshold) FROM stdin;
\.


--
-- Data for Name: sanction_entries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sanction_entries (id, active, added_date, aliases, created_at, date_of_birth, document_number, full_name, last_updated, list_reference, list_type, nationality, updated_at) FROM stdin;
\.


--
-- Data for Name: sanction_screening_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sanction_screening_log (id, branch_code, created_at, match_count, match_details, result, screened_date_of_birth, screened_document_number, screened_name, supervisor_approved, supervisor_name, worker_id, worker_name) FROM stdin;
\.


--
-- Data for Name: scanned_document; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scanned_document (id, created_at, customer_id, deleted_at, document_type, file_name, file_size_bytes, is_deleted, mime_type, notes, scanned_at, scanned_by, storage_path, transaction_id) FROM stdin;
\.


--
-- Data for Name: scheduled_task; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scheduled_task (id, created_at, cron_expression, is_active, last_result, last_run_at, next_run_at, parameters, task_name, task_type, updated_at) FROM stdin;
\.


--
-- Data for Name: seal_number; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.seal_number (id, branch_id, created_at, note, seal_number, seal_type, session_id, used_at, worker_id) FROM stdin;
\.


--
-- Data for Name: seal_tracking; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.seal_tracking (id, version, company_id, transfer_type, transfer_id, seal_number, sealed_at, sealed_by, opened_at, opened_by, transit_status, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: shipment_request; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shipment_request (id, created_at, delivery_date, from_branch_id, notes, request_date, request_number, requested_by_id, status, to_branch_id) FROM stdin;
\.


--
-- Data for Name: shipment_request_item; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.shipment_request_item (id, approved_amount, currency_id, delivered_amount, requested_amount, shipment_request_id) FROM stdin;
\.


--
-- Data for Name: stamp_assignment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stamp_assignment (id, assigned_at, assigned_by, created_at, serial_number, transaction_id, stamp_batch_id) FROM stdin;
\.


--
-- Data for Name: stamp_batch; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stamp_batch (id, branch_id, company_id, created_at, note, received_at, received_by, serial_end, serial_prefix, serial_start) FROM stdin;
\.


--
-- Data for Name: stock_correction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.stock_correction (id, company_id, entity_type, entity_id, currency_code, old_quantity, new_quantity, difference, reason, status, created_at, approved_at, created_by, approved_by) FROM stdin;
\.


--
-- Data for Name: storno_approval; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.storno_approval (id, approved_at, created_at, daily_storno_count, rejection_reason, request_reason, approval_status_did, approved_by_worker_id, branch_id, transaction_id, worker_id) FROM stdin;
\.


--
-- Data for Name: sync_inbox; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sync_inbox (id, idempotency_key, source_node_id, event_type, payload_hash, status, received_at, processed_at) FROM stdin;
\.


--
-- Data for Name: sync_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sync_log (id, completed_at, direction, error_message, record_count, started_at, status, sync_type, branch_id) FROM stdin;
\.


--
-- Data for Name: sync_outbox; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sync_outbox (id, aggregate_type, aggregate_id, event_type, idempotency_key, payload, status, retry_count, next_retry_at, created_at, sent_at) FROM stdin;
\.


--
-- Data for Name: system_parameter; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_parameter (id, category, description, is_active, parameter_key, parameter_type, parameter_value, updated_at, updated_by) FROM stdin;
4e3b0432-016c-4b4e-9d2e-3a59d0e76b0c	EXCHANGE_RATE	Raiffeisen banki partnerség: maximális megengedett eltérés a középárfolyamtól (%). Minden valutára vonatkozik, felülírja az egyedi currency-szintű limitet ha ez kisebb.	t	raiffeisen.max.deviation.percent	DECIMAL	10.0	\N	\N
\.


--
-- Data for Name: token_blacklist; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.token_blacklist (id, token_id, worker_id, blacklisted_at, reason, expires_at) FROM stdin;
\.


--
-- Data for Name: trade; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.trade (id, accepted_at, accepted_by, amount, completed_at, created_at, currency_code, notes, proposed_at, proposed_by, rate, status, from_branch_id, to_branch_id) FROM stdin;
\.


--
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction (id, aml_annual_limit_reached, aml_suspicious, approved_by, created_at, currency_amount, customer_address, customer_document_number, customer_id, customer_name, customer_nationality, discount_amount, discount_percent, discount_type_code, exchange_rate, handling_fee, handling_fee_type, huf_amount, initial_fee, line_count, mtcn, multi_line, notes, payment_method, pos_authorization_code, pos_reference_number, pos_terminal_id, printed, receipt_number, reference_number, reversal_reason, rounding_amount, status, transaction_date, transaction_time, transaction_type, version, branch_id, company_id, currency_id, original_transaction_id, worker_id, linked_receipt_number, partial_refund_amount) FROM stdin;
\.


--
-- Data for Name: transaction_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transaction_line (id, applied_rate, banknote_count, discount_type, huf_value, line_discount, line_number, original_rate, settlement_rate, currency_id, transaction_id) FROM stdin;
\.


--
-- Data for Name: transfer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transfer (id, amount, created_at, difference, handover_printed, huf_value, notes, receipt_printed, received_amount, received_date, received_time, status, transfer_date, transfer_number, transfer_time, transfer_type, version, currency_id, from_branch_id, from_worker_id, to_branch_id, to_worker_id, direction) FROM stdin;
\.


--
-- Data for Name: transfer_document; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transfer_document (id, confirmed_at, courier_pin_hash, created_at, currency_code, delivered_at, destination_id, destination_type, document_number, notes, picked_up_at, quantity, source_id, source_type, status, wac_at_transfer, company_id, courier_id, receiver_id, sender_id) FROM stdin;
\.


--
-- Data for Name: translation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.translation (id, created_at, language_code, message_key, message_value, module, updated_at) FROM stdin;
\.


--
-- Data for Name: vault_bank_transaction; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_bank_transaction (id, company_id, vault_territory_id, transaction_type, currency_code, amount, exchange_rate, huf_amount, bank_name, bank_reference, status, note, created_at, completed_at, created_by, approved_by) FROM stdin;
\.


--
-- Data for Name: vault_collection; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_collection (id, company_id, source_branch_code, source_branch_name, currency_code, amount, status, requested_at, completed_at, note, requested_by) FROM stdin;
\.


--
-- Data for Name: vault_distribution; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_distribution (id, company_id, status, note, created_at, completed_at, created_by) FROM stdin;
\.


--
-- Data for Name: vault_distribution_line; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_distribution_line (id, distribution_id, target_branch_code, target_branch_name, currency_code, amount) FROM stdin;
\.


--
-- Data for Name: vault_territory; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_territory (id, active, base_capital, base_capital_approved_at, name, company_id) FROM stdin;
\.


--
-- Data for Name: vault_transfer; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.vault_transfer (id, company_id, transfer_number, source_vault_id, target_vault_id, source_branch_code, target_branch_code, currency_code, amount, wac_at_transfer, status, requires_supervisor, supervisor_approved_by, supervisor_approved_at, note, created_at, completed_at, created_by, received_by, received_at) FROM stdin;
\.


--
-- Data for Name: worker; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker (id, is_active, code, created_at, created_by, email, last_login_at, name, otp_enabled, otp_user_id, password_changed_at, password_hash, phone, role, updated_at, updated_by, branch_id, company_id) FROM stdin;
2	t	BALI	2026-03-13 16:56:22.447612	\N	bali.henriett.ebc@gmail.com	2026-03-19 06:17:43.11393	Bali Henrietta	\N	\N	\N	$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie	\N	CASHIER	2026-03-19 06:17:43.114614	\N	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c
1	t	BORSI	2026-03-13 16:56:22.447612	\N	borsi.tamas.ebc@gmail.com	2026-03-24 08:23:11.778647	Borsi Tamas	\N	\N	\N	$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie	\N	CASHIER	2026-03-24 08:23:11.779359	\N	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c
3	t	KASZA	2026-03-13 16:56:22.447612	\N	kasza.helga.ebc@gmail.com	2026-03-24 11:25:49.987895	Kasza Helga	\N	\N	\N	$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie	\N	CASHIER	2026-03-24 11:25:49.988619	\N	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c
4	t	KOSA	2026-03-13 17:12:54.465416	\N	kosa.zoltan.ebc@gmail.com	2026-03-24 13:27:19.567734	Kosa Zoltan	\N	\N	\N	$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie	\N	CASHIER	2026-03-24 13:27:19.568341	\N	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c
\.


--
-- Data for Name: worker_attendance; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_attendance (id, branch_id, created_at, ip_address, login_at, logout_at, session_token, user_agent, worker_id) FROM stdin;
\.


--
-- Data for Name: worker_break; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_break (id, approved_by, branch_id, break_end, break_start, created_at, reason, worker_id) FROM stdin;
\.


--
-- Data for Name: worker_commission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_commission (id, branch_id, commission_amount, commission_rate, created_at, paid_at, period_end, period_start, status, total_buys, total_fees, total_sales, updated_at, worker_id) FROM stdin;
\.


--
-- Data for Name: worker_competition; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_competition (id, competition_name, created_at, end_date, rules, start_date, status, updated_at) FROM stdin;
\.


--
-- Data for Name: worker_competition_entry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_competition_entry (id, created_at, rank, score, total_volume, transaction_count, updated_at, worker_id, competition_id) FROM stdin;
\.


--
-- Data for Name: worker_role_assignment; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_role_assignment (id, assigned_at, is_primary, role_def_id, worker_id) FROM stdin;
\.


--
-- Data for Name: worker_role_def; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_role_def (id, code, description_hu, name_hu) FROM stdin;
\.


--
-- Data for Name: worker_role_permission; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_role_permission (permission_id, role_def_id, access_level) FROM stdin;
\.


--
-- Data for Name: worker_session; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.worker_session (id, ip_address, login_at, logout_at, token_id, user_agent, branch_id, company_id, worker_id) FROM stdin;
1	162.158.95.17	2026-03-13 17:29:56.130659	\N	49cb6548-a2aa-4f50-867c-138332b30bca	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
2	162.158.95.68	2026-03-13 17:31:17.045462	\N	cebc0e3f-916d-4e48-a6b9-eadbf1bd96eb	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
3	172.68.224.217	2026-03-13 17:31:52.38821	\N	007608cc-5c78-4d23-a0d1-0a155bf46e3a	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
4	172.68.224.217	2026-03-13 17:32:23.561378	\N	ae5392f4-2970-4651-ba02-c56428b7e281	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
5	162.158.94.152	2026-03-13 17:33:58.200707	\N	8919b7d7-f002-49bc-91c9-84b8eb6c78e7	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
6	172.68.224.217	2026-03-13 17:36:13.749091	\N	73c1dcbe-f82d-45f3-9d46-4d9d2f9f2112	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
7	162.158.95.210	2026-03-13 18:48:23.785408	\N	6777eccb-8c91-4dd2-9626-42edee2158c9	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
8	172.68.224.216	2026-03-13 18:54:40.775274	\N	fdeae2c2-f6a7-4f41-ac00-021240522668	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
9	172.68.224.216	2026-03-13 18:55:10.270729	\N	8d4826ed-5477-47e4-a5fd-074b5988077a	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
10	172.68.224.217	2026-03-13 19:10:28.913524	\N	0c3175f5-0fd4-41f7-97f3-e7f95e088606	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.0 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
11	172.68.224.217	2026-03-17 13:41:44.193988	\N	034f86e8-e247-42eb-a284-1a22c7f44e2e	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
12	172.68.224.217	2026-03-17 13:41:51.439274	\N	53742714-9da1-417b-96e1-999adef608af	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
13	172.68.224.217	2026-03-17 13:41:52.199735	\N	a359484d-070a-423c-b06e-219ab99873ed	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
14	172.68.224.217	2026-03-17 13:54:49.142992	\N	f3846abc-fe45-43e2-9bc8-38fcee1729f9	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
15	172.68.224.216	2026-03-17 15:27:44.818543	\N	e868fb8a-0c3d-45f6-b666-6d15b0d25532	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
16	172.68.224.216	2026-03-17 15:33:29.357632	\N	623c3e76-4829-411b-be6d-4678780ab956	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.5 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
17	108.162.220.123	2026-03-17 15:35:49.6163	\N	5a35483d-08dd-4da4-a452-ba029da636d8	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.5 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
18	172.68.224.217	2026-03-17 15:46:29.550966	\N	23d47f4f-c0e3-452b-a477-52e9a5206f3c	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
19	172.68.224.217	2026-03-17 15:47:12.515063	\N	df23c1d6-c5db-4b31-b258-a642e2169c8f	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
20	172.68.224.217	2026-03-17 15:47:18.915586	\N	00f34f61-1ec1-4f46-af26-05d8b675f7c4	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
21	172.68.224.217	2026-03-17 15:47:25.510199	\N	fc0519c1-aafb-45f6-9186-8e389ecef53a	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
22	172.68.224.217	2026-03-17 15:48:10.93087	\N	86c2a584-7b09-4800-9d57-fd07562e61a3	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
23	172.68.224.217	2026-03-17 15:48:19.346964	\N	718d701e-05d3-4034-a8f0-974e5193e30b	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
24	172.68.224.217	2026-03-17 15:49:54.912908	\N	505f05fd-54ae-424a-8a3e-3ec5412bb87c	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
25	172.68.224.217	2026-03-17 15:50:01.398554	\N	b0b6f70c-a46e-4034-92a4-bf402ee60776	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
26	172.68.224.217	2026-03-17 15:50:07.749703	\N	6cf600e3-ae44-4d87-873c-33834967a6fb	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
27	172.68.224.217	2026-03-17 15:50:16.652264	\N	3be9f076-c795-47ab-80d7-179f7fe37539	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
28	172.68.224.217	2026-03-17 15:50:22.04294	\N	9632aaf4-59d2-4cf8-bd45-6ba8093ea20b	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
29	172.68.224.217	2026-03-17 15:51:15.589633	\N	cfd3b0d1-ecd0-43b8-8fe4-bbdf9787a1e5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
30	104.23.162.141	2026-03-17 16:18:32.540308	\N	20582e69-cb65-4bd1-b27f-0f4c9bc1fd6d	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
31	172.68.224.217	2026-03-17 17:27:07.113651	\N	ba1491fc-628f-4062-ab6f-250c1bd89b0e	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
32	172.68.224.216	2026-03-17 17:30:09.959984	\N	8f5b5a02-2077-4ad4-8623-0ce0fc832027	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
33	172.68.193.213	2026-03-17 18:05:08.310072	\N	671e3908-f2aa-4f0d-a01b-7f907f98ff77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
34	104.23.162.141	2026-03-18 08:19:59.526576	\N	25d45511-8691-4eb5-b756-c39115bfa15e	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
35	162.158.95.215	2026-03-18 08:23:13.375131	\N	aba984dc-5063-4492-8f8a-c43a37f2bca5	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
36	172.71.172.9	2026-03-18 17:20:47.680975	\N	59a8807c-ed78-40ec-ad97-ac71582a4702	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
37	172.71.144.113	2026-03-18 17:23:54.934475	\N	0db70de5-b8ef-4f41-b21b-2f4774f1691d	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/143.0.7499.4 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
38	172.71.144.113	2026-03-18 17:24:09.214478	\N	90e69692-b874-4998-b223-a2551ce59059	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/143.0.7499.4 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
39	172.71.144.113	2026-03-18 17:36:05.151522	\N	d88e6be1-f5d1-4f6a-8baf-4195092d00d9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/143.0.7499.4 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
40	172.70.247.167	2026-03-18 19:27:22.174766	\N	f13f0a0f-c30c-4f21-8a03-dc19f171bdde	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.111.0 Chrome/142.0.7444.265 Electron/39.6.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
41	172.68.224.216	2026-03-18 20:48:57.420066	\N	ed2fc822-ae28-4b8a-a983-b48d8b095507	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
42	172.70.251.155	2026-03-18 21:11:09.310705	\N	b86b34d2-ea33-4024-afa1-6eff0d8d95ea	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
43	172.70.250.190	2026-03-18 21:11:49.07928	\N	46502f6c-430a-484d-a966-a81cd382bea9	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
44	172.68.224.216	2026-03-18 21:11:58.209433	\N	77f57c3f-22e4-4446-99ba-1945223a9aee	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
45	172.68.224.216	2026-03-18 21:12:05.81502	\N	cadb66b4-ce28-4736-9d1b-86ede60e11be	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
46	172.70.251.37	2026-03-18 21:12:17.439019	\N	aca2ca5c-fbbd-4cf1-8451-3ab1994f3dec	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
47	172.70.250.232	2026-03-19 02:14:32.49553	\N	2339ee9a-8bf0-450f-a654-bb0ce8a18d5d	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
48	172.70.250.19	2026-03-19 02:14:43.273282	\N	93ea80a2-f560-40a4-a4f6-b630294ad586	Mozilla/5.0 (Windows NT 10.0; Microsoft Windows 10.0.26200; hu-HU) PowerShell/7.5.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
49	104.23.211.20	2026-03-19 06:17:38.159397	\N	cedb670b-8939-4b42-8866-c011f643cbfc	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
50	104.23.213.157	2026-03-19 06:17:39.958299	\N	47a3b29a-f2b7-40c1-849e-4474bfe34834	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
51	172.70.38.42	2026-03-19 06:17:41.533728	\N	c8c7368c-4971-4e22-8466-ab222d574f50	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
52	172.70.35.19	2026-03-19 06:17:43.109	\N	6cbe61bc-04b1-43fa-a571-126bb47f0253	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	2
53	104.23.211.20	2026-03-19 06:17:44.524815	\N	69fb2cba-51d3-4db3-888f-6bf535ea824f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
54	104.23.213.157	2026-03-19 06:17:45.915059	\N	0cc5e80b-b521-4577-9412-8921bc174f37	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
55	104.23.209.203	2026-03-19 06:17:47.60655	\N	e562d6fa-7959-4dc1-b1c2-ed5c36fa3c90	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
56	141.101.105.41	2026-03-20 09:13:33.191676	\N	5d170e2f-7f35-4637-a0ed-c50b19948131	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
57	162.158.111.59	2026-03-23 10:17:42.946452	\N	bcde3baa-f45b-4728-afc4-221a74ff1491	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
58	108.162.220.123	2026-03-23 10:47:07.628025	\N	40ce14ee-af7d-4b08-aca6-223fa07fcf5b	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.1.0 Chrome/146.0.7680.80 Electron/41.0.3 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
59	108.162.220.122	2026-03-23 12:51:58.938147	\N	2c3d4467-a2a4-4362-9779-920709ca57e7	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.1.0 Chrome/146.0.7680.80 Electron/41.0.3 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
60	104.23.162.141	2026-03-23 12:52:39.542357	\N	05981193-188d-43dc-9999-6185ba73f82e	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Code/1.112.0 Chrome/142.0.7444.265 Electron/39.8.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
61	172.68.194.140	2026-03-23 14:29:05.237155	\N	830bd751-6811-4437-b54f-d00d9eb79599	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Cursor/2.6.20 Chrome/142.0.7444.265 Electron/39.8.1 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
62	172.68.192.235	2026-03-23 17:19:54.827596	\N	f358193e-b446-4d76-8d64-f3279ea1da6c	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
63	162.158.111.15	2026-03-23 17:39:39.431026	\N	2e73a7fe-9a56-4993-b45a-55fff5533546	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
64	162.158.95.119	2026-03-23 17:42:37.68079	\N	9decc7a1-dbdc-4648-b5ff-4615626cbb86	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
65	172.71.144.112	2026-03-23 17:44:31.519853	\N	02f3b3bf-1d67-48b6-a192-dad7f8b9d07d	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
66	172.71.172.8	2026-03-23 17:44:44.390878	\N	d86fc836-b2cf-4090-a58d-1b1e1f2b8c74	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
67	172.69.151.36	2026-03-23 17:50:09.660134	\N	ae5b17b7-42e4-4d70-a94f-6316ea5fede1	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
68	172.69.151.36	2026-03-23 17:50:22.41251	\N	5a3198b9-01e9-4b03-84e4-d4a06442b4e1	curl/8.18.0	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
69	104.23.162.141	2026-03-23 18:04:26.677063	\N	799e1525-bd19-4251-affe-4471ac3f1854	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
70	108.162.220.122	2026-03-23 18:04:41.647316	\N	cd061014-b6b1-49ce-bca7-3c88128a91d7	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
71	104.23.162.141	2026-03-23 18:30:29.072257	\N	bcc3dc2b-b257-4e21-8dec-80cf4ab4a448	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
72	104.23.162.141	2026-03-23 18:30:55.391794	\N	7f079aab-5d7f-4937-82c3-449df68aedf3	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
73	108.162.220.123	2026-03-23 18:30:57.064679	\N	e485e646-1b70-4fbb-8dd4-ebde0d35e0f7	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
74	104.23.162.141	2026-03-23 19:15:26.946641	\N	8c7866b2-04ca-4435-933e-096849400c05	python-requests/2.32.5	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
75	162.158.111.171	2026-03-24 07:54:48.672181	\N	8629f18d-50e5-4128-a633-0c35701b0d44	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
76	162.158.110.118	2026-03-24 08:23:11.769745	\N	d6bca7b4-9841-4732-bcf8-9174ee0fdda2	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	1
77	162.158.111.212	2026-03-24 11:25:49.979102	\N	4a96d20e-e751-41d9-834f-53e282702789	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.0.6 Chrome/130.0.6723.191 Electron/33.4.11 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	3
78	104.23.162.141	2026-03-24 13:26:46.371707	\N	0ca758da-3708-4c8c-abdd-9e321dc9f5a9	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) valuta-penztar/1.1.0 Chrome/146.0.7680.80 Electron/41.0.3 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
79	162.158.111.71	2026-03-24 13:27:19.562682	\N	cf813694-a59d-4b2e-9aa6-c42f761d97a1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36	dd29ef03-c7cc-4fb8-9106-045991627a85	17015396-a878-4677-ab8e-05f2f7a8ee6c	4
\.


--
-- Data for Name: workstation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.workstation (id, branch_id, code, created_at, ip_address, is_active, last_heartbeat, mac_address, name, updated_at) FROM stdin;
\.


--
-- Data for Name: wu_balances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wu_balances (id, huf_balance, last_receipt_buy, last_receipt_customer_in, last_receipt_customer_out, last_receipt_sell, updated_at, usd_balance, branch_id, company_id) FROM stdin;
\.


--
-- Data for Name: wu_customers; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wu_customers (id, address, created_at, date_of_birth, first_name, id_number, id_type, last_name, nationality, phone, updated_at, wu_customer_code, customer_id, company_id) FROM stdin;
\.


--
-- Data for Name: wu_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wu_transactions (id, amount_huf, amount_usd, created_at, destination_country, exchange_rate, fee_amount, mtcn, receipt_number, receiver_name, sender_name, status, transaction_date, transaction_type, branch_id, worker_id, wu_customer_id, reversed_transaction_id, reversal_reason, company_id) FROM stdin;
\.


--
-- Name: archived_monthly_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.archived_monthly_transaction_id_seq', 1, false);


--
-- Name: archived_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.archived_transactions_id_seq', 1, false);


--
-- Name: cash_balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.cash_balance_id_seq', 6, true);


--
-- Name: circular_acknowledgment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.circular_acknowledgment_id_seq', 1, false);


--
-- Name: circular_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.circular_id_seq', 1, false);


--
-- Name: circular_sequence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.circular_sequence_id_seq', 1, false);


--
-- Name: currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.currency_id_seq', 21, true);


--
-- Name: currency_stock_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.currency_stock_id_seq', 4, true);


--
-- Name: customer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.customer_id_seq', 1, false);


--
-- Name: daily_balance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_balance_id_seq', 1, false);


--
-- Name: daily_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_report_id_seq', 1, false);


--
-- Name: daily_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.daily_session_id_seq', 16, true);


--
-- Name: denomination_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.denomination_id_seq', 1, false);


--
-- Name: employee_address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_address_id_seq', 1, false);


--
-- Name: employee_bank_account_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_bank_account_id_seq', 1, false);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.employee_id_seq', 1, false);


--
-- Name: evening_sync_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.evening_sync_log_id_seq', 1, false);


--
-- Name: exchange_rate_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exchange_rate_id_seq', 23, true);


--
-- Name: exchange_rate_source_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.exchange_rate_source_id_seq', 1, false);


--
-- Name: feor_code_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.feor_code_id_seq', 1, false);


--
-- Name: handling_fee_bracket_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.handling_fee_bracket_id_seq', 1, false);


--
-- Name: initial_fee_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.initial_fee_config_id_seq', 1, false);


--
-- Name: inventory_movement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_movement_id_seq', 1, false);


--
-- Name: inventory_regeneration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_regeneration_id_seq', 1, false);


--
-- Name: inventory_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventory_summary_id_seq', 1, false);


--
-- Name: material_receipt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_receipt_id_seq', 1, false);


--
-- Name: material_receipt_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_receipt_line_id_seq', 1, false);


--
-- Name: material_receipt_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.material_receipt_seq', 1, false);


--
-- Name: mnb_exchange_rate_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.mnb_exchange_rate_cache_id_seq', 17, true);


--
-- Name: monthly_closing_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.monthly_closing_summary_id_seq', 1, false);


--
-- Name: profit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.profit_log_id_seq', 1, false);


--
-- Name: rate_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rate_history_id_seq', 1, false);


--
-- Name: receipt_sequence_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.receipt_sequence_id_seq', 1, false);


--
-- Name: reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reservation_id_seq', 1, false);


--
-- Name: rounding_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rounding_rule_id_seq', 1, false);


--
-- Name: seal_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seal_tracking_id_seq', 1, false);


--
-- Name: stock_correction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stock_correction_id_seq', 1, false);


--
-- Name: token_blacklist_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.token_blacklist_id_seq', 1, false);


--
-- Name: transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_id_seq', 1, false);


--
-- Name: transaction_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transaction_line_id_seq', 1, false);


--
-- Name: transfer_document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transfer_document_id_seq', 1, false);


--
-- Name: transfer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.transfer_id_seq', 1, false);


--
-- Name: translation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.translation_id_seq', 1, false);


--
-- Name: vault_bank_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_bank_transaction_id_seq', 1, false);


--
-- Name: vault_collection_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_collection_id_seq', 1, false);


--
-- Name: vault_distribution_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_distribution_id_seq', 1, false);


--
-- Name: vault_distribution_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_distribution_line_id_seq', 1, false);


--
-- Name: vault_territory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_territory_id_seq', 1, false);


--
-- Name: vault_transfer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_transfer_id_seq', 1, false);


--
-- Name: vault_transfer_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vault_transfer_seq', 1, false);


--
-- Name: worker_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.worker_id_seq', 11, true);


--
-- Name: worker_role_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.worker_role_assignment_id_seq', 1, false);


--
-- Name: worker_role_def_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.worker_role_def_id_seq', 1, false);


--
-- Name: worker_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.worker_session_id_seq', 79, true);


--
-- Name: aml_report aml_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aml_report
    ADD CONSTRAINT aml_report_pkey PRIMARY KEY (id);


--
-- Name: aml_threshold aml_threshold_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aml_threshold
    ADD CONSTRAINT aml_threshold_pkey PRIMARY KEY (id);


--
-- Name: anonymous_report anonymous_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anonymous_report
    ADD CONSTRAINT anonymous_report_pkey PRIMARY KEY (id);


--
-- Name: archive_task archive_task_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archive_task
    ADD CONSTRAINT archive_task_pkey PRIMARY KEY (id);


--
-- Name: archived_monthly_transaction archived_monthly_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_monthly_transaction
    ADD CONSTRAINT archived_monthly_transaction_pkey PRIMARY KEY (id);


--
-- Name: archived_transactions archived_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_transactions
    ADD CONSTRAINT archived_transactions_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: authorization_log authorization_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorization_log
    ADD CONSTRAINT authorization_log_pkey PRIMARY KEY (id);


--
-- Name: authorized_representative authorized_representative_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.authorized_representative
    ADD CONSTRAINT authorized_representative_pkey PRIMARY KEY (id);


--
-- Name: backup_record backup_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backup_record
    ADD CONSTRAINT backup_record_pkey PRIMARY KEY (id);


--
-- Name: branch_group branch_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_group
    ADD CONSTRAINT branch_group_pkey PRIMARY KEY (id);


--
-- Name: branch branch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT branch_pkey PRIMARY KEY (id);


--
-- Name: branch_status branch_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_status
    ADD CONSTRAINT branch_status_pkey PRIMARY KEY (id);


--
-- Name: camera_access_log camera_access_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_access_log
    ADD CONSTRAINT camera_access_log_pkey PRIMARY KEY (id);


--
-- Name: camera_config camera_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_config
    ADD CONSTRAINT camera_config_pkey PRIMARY KEY (id);


--
-- Name: camera_export_request camera_export_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_export_request
    ADD CONSTRAINT camera_export_request_pkey PRIMARY KEY (id);


--
-- Name: camera_recording camera_recording_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_recording
    ADD CONSTRAINT camera_recording_pkey PRIMARY KEY (id);


--
-- Name: camera_segment_hash camera_segment_hash_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_segment_hash
    ADD CONSTRAINT camera_segment_hash_pkey PRIMARY KEY (id);


--
-- Name: camera_transaction_link camera_transaction_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_transaction_link
    ADD CONSTRAINT camera_transaction_link_pkey PRIMARY KEY (id);


--
-- Name: cash_balance cash_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance
    ADD CONSTRAINT cash_balance_pkey PRIMARY KEY (id);


--
-- Name: cash_desk_break cash_desk_break_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_desk_break
    ADD CONSTRAINT cash_desk_break_pkey PRIMARY KEY (id);


--
-- Name: cash_register_event cash_register_event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_register_event
    ADD CONSTRAINT cash_register_event_pkey PRIMARY KEY (id);


--
-- Name: chain_of_custody_record chain_of_custody_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain_of_custody_record
    ADD CONSTRAINT chain_of_custody_record_pkey PRIMARY KEY (id);


--
-- Name: circular_acknowledgment circular_acknowledgment_circular_id_worker_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_acknowledgment
    ADD CONSTRAINT circular_acknowledgment_circular_id_worker_id_key UNIQUE (circular_id, worker_id);


--
-- Name: circular_acknowledgment circular_acknowledgment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_acknowledgment
    ADD CONSTRAINT circular_acknowledgment_pkey PRIMARY KEY (id);


--
-- Name: circular circular_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular
    ADD CONSTRAINT circular_pkey PRIMARY KEY (id);


--
-- Name: circular_sequence circular_sequence_company_id_prefix_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_sequence
    ADD CONSTRAINT circular_sequence_company_id_prefix_key UNIQUE (company_id, prefix);


--
-- Name: circular_sequence circular_sequence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_sequence
    ADD CONSTRAINT circular_sequence_pkey PRIMARY KEY (id);


--
-- Name: closing_control closing_control_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_control
    ADD CONSTRAINT closing_control_pkey PRIMARY KEY (id);


--
-- Name: closing_wizard closing_wizard_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard
    ADD CONSTRAINT closing_wizard_pkey PRIMARY KEY (id);


--
-- Name: closing_wizard_step closing_wizard_step_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard_step
    ADD CONSTRAINT closing_wizard_step_pkey PRIMARY KEY (id);


--
-- Name: collected_inventory collected_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collected_inventory
    ADD CONSTRAINT collected_inventory_pkey PRIMARY KEY (id);


--
-- Name: collected_transaction collected_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collected_transaction
    ADD CONSTRAINT collected_transaction_pkey PRIMARY KEY (id);


--
-- Name: commission_calculation commission_calculation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_calculation
    ADD CONSTRAINT commission_calculation_pkey PRIMARY KEY (id);


--
-- Name: commission_rate commission_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_rate
    ADD CONSTRAINT commission_rate_pkey PRIMARY KEY (id);


--
-- Name: commission_rule commission_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_rule
    ADD CONSTRAINT commission_rule_pkey PRIMARY KEY (id);


--
-- Name: company company_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT company_pkey PRIMARY KEY (id);


--
-- Name: competitor competitor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor
    ADD CONSTRAINT competitor_pkey PRIMARY KEY (id);


--
-- Name: competitor_rates competitor_rates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_rates
    ADD CONSTRAINT competitor_rates_pkey PRIMARY KEY (id);


--
-- Name: contribution contribution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contribution
    ADD CONSTRAINT contribution_pkey PRIMARY KEY (id);


--
-- Name: currency_group currency_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_group
    ADD CONSTRAINT currency_group_pkey PRIMARY KEY (id);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (id);


--
-- Name: currency_stock currency_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_stock
    ADD CONSTRAINT currency_stock_pkey PRIMARY KEY (id);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: customer_restriction customer_restriction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_restriction
    ADD CONSTRAINT customer_restriction_pkey PRIMARY KEY (id);


--
-- Name: customer_screening_log customer_screening_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_screening_log
    ADD CONSTRAINT customer_screening_log_pkey PRIMARY KEY (id);


--
-- Name: daily_balance daily_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_balance
    ADD CONSTRAINT daily_balance_pkey PRIMARY KEY (id);


--
-- Name: daily_checklist_item daily_checklist_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist_item
    ADD CONSTRAINT daily_checklist_item_pkey PRIMARY KEY (id);


--
-- Name: daily_checklist daily_checklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist
    ADD CONSTRAINT daily_checklist_pkey PRIMARY KEY (id);


--
-- Name: daily_report daily_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_report
    ADD CONSTRAINT daily_report_pkey PRIMARY KEY (id);


--
-- Name: daily_session daily_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session
    ADD CONSTRAINT daily_session_pkey PRIMARY KEY (id);


--
-- Name: darius_daily_report darius_daily_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_daily_report
    ADD CONSTRAINT darius_daily_report_pkey PRIMARY KEY (id);


--
-- Name: darius_report_line darius_report_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_report_line
    ADD CONSTRAINT darius_report_line_pkey PRIMARY KEY (id);


--
-- Name: data_collection data_collection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_collection
    ADD CONSTRAINT data_collection_pkey PRIMARY KEY (id);


--
-- Name: data_import_jobs data_import_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_import_jobs
    ADD CONSTRAINT data_import_jobs_pkey PRIMARY KEY (id);


--
-- Name: decade_report_line decade_report_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report_line
    ADD CONSTRAINT decade_report_line_pkey PRIMARY KEY (id);


--
-- Name: decade_report decade_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report
    ADD CONSTRAINT decade_report_pkey PRIMARY KEY (id);


--
-- Name: denomination_balance denomination_balance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination_balance
    ADD CONSTRAINT denomination_balance_pkey PRIMARY KEY (id);


--
-- Name: denomination_count denomination_count_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination_count
    ADD CONSTRAINT denomination_count_pkey PRIMARY KEY (id);


--
-- Name: denomination denomination_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination
    ADD CONSTRAINT denomination_pkey PRIMARY KEY (id);


--
-- Name: dictionary dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dictionary
    ADD CONSTRAINT dictionary_pkey PRIMARY KEY (id);


--
-- Name: document document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- Name: email_account email_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT email_account_pkey PRIMARY KEY (id);


--
-- Name: email_cache email_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_cache
    ADD CONSTRAINT email_cache_pkey PRIMARY KEY (id);


--
-- Name: employee_address employee_address_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_address
    ADD CONSTRAINT employee_address_pkey PRIMARY KEY (id);


--
-- Name: employee_bank_account employee_bank_account_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_bank_account
    ADD CONSTRAINT employee_bank_account_pkey PRIMARY KEY (id);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- Name: error_logs error_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_logs
    ADD CONSTRAINT error_logs_pkey PRIMARY KEY (id);


--
-- Name: evening_closing evening_closing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evening_closing
    ADD CONSTRAINT evening_closing_pkey PRIMARY KEY (id);


--
-- Name: evening_sync_log evening_sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.evening_sync_log
    ADD CONSTRAINT evening_sync_log_pkey PRIMARY KEY (id);


--
-- Name: exchange_rate_display exchange_rate_display_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate_display
    ADD CONSTRAINT exchange_rate_display_pkey PRIMARY KEY (id);


--
-- Name: exchange_rate exchange_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate
    ADD CONSTRAINT exchange_rate_pkey PRIMARY KEY (id);


--
-- Name: exchange_rate_source exchange_rate_source_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate_source
    ADD CONSTRAINT exchange_rate_source_pkey PRIMARY KEY (id);


--
-- Name: fee_discount fee_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_discount
    ADD CONSTRAINT fee_discount_pkey PRIMARY KEY (id);


--
-- Name: fee_rate fee_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_rate
    ADD CONSTRAINT fee_rate_pkey PRIMARY KEY (id);


--
-- Name: fee_type fee_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_type
    ADD CONSTRAINT fee_type_pkey PRIMARY KEY (id);


--
-- Name: feor_code feor_code_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feor_code
    ADD CONSTRAINT feor_code_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: ftp_sync_log ftp_sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ftp_sync_log
    ADD CONSTRAINT ftp_sync_log_pkey PRIMARY KEY (id);


--
-- Name: handling_fee_bracket handling_fee_bracket_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_bracket
    ADD CONSTRAINT handling_fee_bracket_pkey PRIMARY KEY (id);


--
-- Name: handling_fee_decade_report handling_fee_decade_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_decade_report
    ADD CONSTRAINT handling_fee_decade_report_pkey PRIMARY KEY (id);


--
-- Name: handling_fee_transaction handling_fee_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_transaction
    ADD CONSTRAINT handling_fee_transaction_pkey PRIMARY KEY (id);


--
-- Name: handover_sheet handover_sheet_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_sheet
    ADD CONSTRAINT handover_sheet_pkey PRIMARY KEY (id);


--
-- Name: hrk_transaction hrk_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hrk_transaction
    ADD CONSTRAINT hrk_transaction_pkey PRIMARY KEY (id);


--
-- Name: seal_number idx_seal_number_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_number
    ADD CONSTRAINT idx_seal_number_unique UNIQUE (seal_number);


--
-- Name: shipment_request idx_shipment_request_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_request
    ADD CONSTRAINT idx_shipment_request_number UNIQUE (request_number);


--
-- Name: translation idx_translation_lang_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation
    ADD CONSTRAINT idx_translation_lang_key UNIQUE (language_code, message_key);


--
-- Name: initial_fee_config initial_fee_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initial_fee_config
    ADD CONSTRAINT initial_fee_config_pkey PRIMARY KEY (id);


--
-- Name: inventory_movement inventory_movement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT inventory_movement_pkey PRIMARY KEY (id);


--
-- Name: inventory_regeneration inventory_regeneration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_regeneration
    ADD CONSTRAINT inventory_regeneration_pkey PRIMARY KEY (id);


--
-- Name: inventory_summary inventory_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_summary
    ADD CONSTRAINT inventory_summary_pkey PRIMARY KEY (id);


--
-- Name: led_display_config led_display_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.led_display_config
    ADD CONSTRAINT led_display_config_pkey PRIMARY KEY (id);


--
-- Name: led_display led_display_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.led_display
    ADD CONSTRAINT led_display_pkey PRIMARY KEY (id);


--
-- Name: license license_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license
    ADD CONSTRAINT license_pkey PRIMARY KEY (id);


--
-- Name: material_receipt_line material_receipt_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt_line
    ADD CONSTRAINT material_receipt_line_pkey PRIMARY KEY (id);


--
-- Name: material_receipt material_receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt
    ADD CONSTRAINT material_receipt_pkey PRIMARY KEY (id);


--
-- Name: mnb_exchange_rate_cache mnb_exchange_rate_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_exchange_rate_cache
    ADD CONSTRAINT mnb_exchange_rate_cache_pkey PRIMARY KEY (id);


--
-- Name: mnb_report_line mnb_report_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_report_line
    ADD CONSTRAINT mnb_report_line_pkey PRIMARY KEY (id);


--
-- Name: mnb_report mnb_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_report
    ADD CONSTRAINT mnb_report_pkey PRIMARY KEY (id);


--
-- Name: monthly_closing monthly_closing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing
    ADD CONSTRAINT monthly_closing_pkey PRIMARY KEY (id);


--
-- Name: monthly_closing_summary monthly_closing_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing_summary
    ADD CONSTRAINT monthly_closing_summary_pkey PRIMARY KEY (id);


--
-- Name: nav_closing_line nav_closing_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_closing_line
    ADD CONSTRAINT nav_closing_line_pkey PRIMARY KEY (id);


--
-- Name: nav_closing nav_closing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_closing
    ADD CONSTRAINT nav_closing_pkey PRIMARY KEY (id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organizational_system_parameter organizational_system_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizational_system_parameter
    ADD CONSTRAINT organizational_system_parameter_pkey PRIMARY KEY (id);


--
-- Name: own_company own_company_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.own_company
    ADD CONSTRAINT own_company_pkey PRIMARY KEY (id);


--
-- Name: packaging_record packaging_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packaging_record
    ADD CONSTRAINT packaging_record_pkey PRIMARY KEY (id);


--
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- Name: police_request police_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.police_request
    ADD CONSTRAINT police_request_pkey PRIMARY KEY (id);


--
-- Name: pos_terminal pos_terminal_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_terminal
    ADD CONSTRAINT pos_terminal_pkey PRIMARY KEY (id);


--
-- Name: print_template print_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.print_template
    ADD CONSTRAINT print_template_pkey PRIMARY KEY (id);


--
-- Name: profit_log profit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_log
    ADD CONSTRAINT profit_log_pkey PRIMARY KEY (id);


--
-- Name: prohibited_company prohibited_company_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prohibited_company
    ADD CONSTRAINT prohibited_company_pkey PRIMARY KEY (id);


--
-- Name: prohibited_person prohibited_person_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prohibited_person
    ADD CONSTRAINT prohibited_person_pkey PRIMARY KEY (id);


--
-- Name: rate_approval rate_approval_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_approval
    ADD CONSTRAINT rate_approval_pkey PRIMARY KEY (id);


--
-- Name: rate_category rate_category_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_category
    ADD CONSTRAINT rate_category_pkey PRIMARY KEY (id);


--
-- Name: rate_discount rate_discount_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_discount
    ADD CONSTRAINT rate_discount_pkey PRIMARY KEY (id);


--
-- Name: rate_history rate_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_history
    ADD CONSTRAINT rate_history_pkey PRIMARY KEY (id);


--
-- Name: rate_publication rate_publication_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_publication
    ADD CONSTRAINT rate_publication_pkey PRIMARY KEY (id);


--
-- Name: rate_template rate_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_template
    ADD CONSTRAINT rate_template_pkey PRIMARY KEY (id);


--
-- Name: rate_workgroup_branch rate_workgroup_branch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup_branch
    ADD CONSTRAINT rate_workgroup_branch_pkey PRIMARY KEY (workgroup_id, branch_id);


--
-- Name: rate_workgroup rate_workgroup_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup
    ADD CONSTRAINT rate_workgroup_pkey PRIMARY KEY (id);


--
-- Name: receipt receipt_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt
    ADD CONSTRAINT receipt_pkey PRIMARY KEY (id);


--
-- Name: receipt_sequence receipt_sequence_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt_sequence
    ADD CONSTRAINT receipt_sequence_pkey PRIMARY KEY (id);


--
-- Name: reservation reservation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id);


--
-- Name: role_permission role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT role_permission_pkey PRIMARY KEY (role_id, permission_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: rounding_rule rounding_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounding_rule
    ADD CONSTRAINT rounding_rule_pkey PRIMARY KEY (id);


--
-- Name: sanction_entries sanction_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sanction_entries
    ADD CONSTRAINT sanction_entries_pkey PRIMARY KEY (id);


--
-- Name: sanction_screening_log sanction_screening_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sanction_screening_log
    ADD CONSTRAINT sanction_screening_log_pkey PRIMARY KEY (id);


--
-- Name: scanned_document scanned_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scanned_document
    ADD CONSTRAINT scanned_document_pkey PRIMARY KEY (id);


--
-- Name: scheduled_task scheduled_task_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_task
    ADD CONSTRAINT scheduled_task_pkey PRIMARY KEY (id);


--
-- Name: seal_number seal_number_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_number
    ADD CONSTRAINT seal_number_pkey PRIMARY KEY (id);


--
-- Name: seal_tracking seal_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_tracking
    ADD CONSTRAINT seal_tracking_pkey PRIMARY KEY (id);


--
-- Name: shipment_request_item shipment_request_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_request_item
    ADD CONSTRAINT shipment_request_item_pkey PRIMARY KEY (id);


--
-- Name: shipment_request shipment_request_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_request
    ADD CONSTRAINT shipment_request_pkey PRIMARY KEY (id);


--
-- Name: stamp_assignment stamp_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stamp_assignment
    ADD CONSTRAINT stamp_assignment_pkey PRIMARY KEY (id);


--
-- Name: stamp_batch stamp_batch_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stamp_batch
    ADD CONSTRAINT stamp_batch_pkey PRIMARY KEY (id);


--
-- Name: stock_correction stock_correction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stock_correction
    ADD CONSTRAINT stock_correction_pkey PRIMARY KEY (id);


--
-- Name: storno_approval storno_approval_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT storno_approval_pkey PRIMARY KEY (id);


--
-- Name: sync_inbox sync_inbox_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_inbox
    ADD CONSTRAINT sync_inbox_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: sync_inbox sync_inbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_inbox
    ADD CONSTRAINT sync_inbox_pkey PRIMARY KEY (id);


--
-- Name: sync_log sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_log
    ADD CONSTRAINT sync_log_pkey PRIMARY KEY (id);


--
-- Name: sync_outbox sync_outbox_idempotency_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_outbox
    ADD CONSTRAINT sync_outbox_idempotency_key_key UNIQUE (idempotency_key);


--
-- Name: sync_outbox sync_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_outbox
    ADD CONSTRAINT sync_outbox_pkey PRIMARY KEY (id);


--
-- Name: system_parameter system_parameter_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_parameter
    ADD CONSTRAINT system_parameter_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_token_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_token_id_key UNIQUE (token_id);


--
-- Name: trade trade_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade
    ADD CONSTRAINT trade_pkey PRIMARY KEY (id);


--
-- Name: transaction_line transaction_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_line
    ADD CONSTRAINT transaction_line_pkey PRIMARY KEY (id);


--
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (id);


--
-- Name: transfer_document transfer_document_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document
    ADD CONSTRAINT transfer_document_pkey PRIMARY KEY (id);


--
-- Name: transfer transfer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT transfer_pkey PRIMARY KEY (id);


--
-- Name: translation translation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation
    ADD CONSTRAINT translation_pkey PRIMARY KEY (id);


--
-- Name: cash_balance uk2vf5a63ep5394iipeqva65c7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance
    ADD CONSTRAINT uk2vf5a63ep5394iipeqva65c7 UNIQUE (branch_id, currency_id);


--
-- Name: denomination_balance uk4g8glqo7rah6ebhlltscwyvdx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination_balance
    ADD CONSTRAINT uk4g8glqo7rah6ebhlltscwyvdx UNIQUE (cash_desk_id, denomination_id);


--
-- Name: worker_role_assignment uk4p0tf5sfgkqju9ea3tkbbe3we; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_assignment
    ADD CONSTRAINT uk4p0tf5sfgkqju9ea3tkbbe3we UNIQUE (worker_id, role_def_id);


--
-- Name: email_cache uk83jaiuwyvfqtvwlb0qbbmclr0; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_cache
    ADD CONSTRAINT uk83jaiuwyvfqtvwlb0qbbmclr0 UNIQUE (email_account_id, gmail_message_id);


--
-- Name: organization uk_27tbqbmjb9kf4al49ojliavjt; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT uk_27tbqbmjb9kf4al49ojliavjt UNIQUE (code);


--
-- Name: error_logs uk_2uk20408yx23iqxjl445flo0x; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.error_logs
    ADD CONSTRAINT uk_2uk20408yx23iqxjl445flo0x UNIQUE (fingerprint);


--
-- Name: fee_type uk_3gef756klr7e0e2ua32iogumj; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_type
    ADD CONSTRAINT uk_3gef756klr7e0e2ua32iogumj UNIQUE (code);


--
-- Name: branch_status uk_6aspr4ib0pv8vmgbu4uc875qc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_status
    ADD CONSTRAINT uk_6aspr4ib0pv8vmgbu4uc875qc UNIQUE (branch_id);


--
-- Name: aml_threshold uk_74y01bto5d0cjwugaxtcnbqb5; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aml_threshold
    ADD CONSTRAINT uk_74y01bto5d0cjwugaxtcnbqb5 UNIQUE (threshold_type);


--
-- Name: feor_code uk_865l1c8tefl67bmwcpds1oncs; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feor_code
    ADD CONSTRAINT uk_865l1c8tefl67bmwcpds1oncs UNIQUE (code);


--
-- Name: company uk_8pha7u18i980jasccc4ekh7gg; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.company
    ADD CONSTRAINT uk_8pha7u18i980jasccc4ekh7gg UNIQUE (code);


--
-- Name: permission uk_a7ujv987la0i7a0o91ueevchc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT uk_a7ujv987la0i7a0o91ueevchc UNIQUE (code);


--
-- Name: role uk_c36say97xydpmgigg38qv5l2p; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT uk_c36say97xydpmgigg38qv5l2p UNIQUE (code);


--
-- Name: camera_segment_hash uk_camera_hash_sequence; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_segment_hash
    ADD CONSTRAINT uk_camera_hash_sequence UNIQUE (branch_id, camera_id, sequence_number);


--
-- Name: commission_calculation uk_comm_calc_worker_period; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.commission_calculation
    ADD CONSTRAINT uk_comm_calc_worker_period UNIQUE (worker_id, period);


--
-- Name: worker_competition_entry uk_comp_entry; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_competition_entry
    ADD CONSTRAINT uk_comp_entry UNIQUE (competition_id, worker_id);


--
-- Name: daily_report uk_daily_report_branch_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_report
    ADD CONSTRAINT uk_daily_report_branch_date UNIQUE (branch_id, report_date);


--
-- Name: darius_daily_report uk_darius_report_company_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_daily_report
    ADD CONSTRAINT uk_darius_report_company_date UNIQUE (company_id, report_date);


--
-- Name: decade_report_line uk_decade_line_report_currency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report_line
    ADD CONSTRAINT uk_decade_line_report_currency UNIQUE (decade_report_id, currency_code);


--
-- Name: decade_report uk_decade_report_branch_year_decade; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report
    ADD CONSTRAINT uk_decade_report_branch_year_decade UNIQUE (branch_id, year, decade);


--
-- Name: workstation uk_ehpsna3rcdy3jp8t8qdf9d9sf; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workstation
    ADD CONSTRAINT uk_ehpsna3rcdy3jp8t8qdf9d9sf UNIQUE (code);


--
-- Name: branch uk_f0gwphsg8g5i4rfbyeo6vvf11; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT uk_f0gwphsg8g5i4rfbyeo6vvf11 UNIQUE (code);


--
-- Name: pos_terminal uk_f6qt8x339t7li5xyd1voygyl7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pos_terminal
    ADD CONSTRAINT uk_f6qt8x339t7li5xyd1voygyl7 UNIQUE (terminal_id);


--
-- Name: currency_group uk_f7bakcom01i2alrih2yque9vh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_group
    ADD CONSTRAINT uk_f7bakcom01i2alrih2yque9vh UNIQUE (code);


--
-- Name: rounding_rule uk_fj6m1rvk7lfw5sgg8igba0pxd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounding_rule
    ADD CONSTRAINT uk_fj6m1rvk7lfw5sgg8igba0pxd UNIQUE (currency_code);


--
-- Name: system_parameter uk_fklorvbynxmc618u47kqsedbw; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_parameter
    ADD CONSTRAINT uk_fklorvbynxmc618u47kqsedbw UNIQUE (parameter_key);


--
-- Name: handover_sheet uk_gftqd2q8w5kgierxqpn6bl0rp; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handover_sheet
    ADD CONSTRAINT uk_gftqd2q8w5kgierxqpn6bl0rp UNIQUE (sheet_number);


--
-- Name: currency uk_h84pd2rtr12isnifnj655rkra; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT uk_h84pd2rtr12isnifnj655rkra UNIQUE (code);


--
-- Name: handling_fee_decade_report uk_hf_decade_branch_year_decade; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_decade_report
    ADD CONSTRAINT uk_hf_decade_branch_year_decade UNIQUE (branch_id, year, decade);


--
-- Name: worker_role_def uk_hj5hkrqswcni832g3a4ja6f2y; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_def
    ADD CONSTRAINT uk_hj5hkrqswcni832g3a4ja6f2y UNIQUE (code);


--
-- Name: inventory_movement uk_inv_mov_ref_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT uk_inv_mov_ref_number UNIQUE (reference_number);


--
-- Name: inventory_summary uk_inv_sum_branch_currency_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_summary
    ADD CONSTRAINT uk_inv_sum_branch_currency_date UNIQUE (branch_id, currency_id, summary_date);


--
-- Name: stamp_assignment uk_j6xo43lijsuabnaya3osfrphq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stamp_assignment
    ADD CONSTRAINT uk_j6xo43lijsuabnaya3osfrphq UNIQUE (serial_number);


--
-- Name: branch_group uk_neetakt150dcxa5td6yax09bq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_group
    ADD CONSTRAINT uk_neetakt150dcxa5td6yax09bq UNIQUE (code);


--
-- Name: rate_workgroup uk_pq9ftwxofiiv3dqabwwavd5wd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup
    ADD CONSTRAINT uk_pq9ftwxofiiv3dqabwwavd5wd UNIQUE (code);


--
-- Name: fee_discount uk_r9tlvfq2gon8aci853i99v5ya; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fee_discount
    ADD CONSTRAINT uk_r9tlvfq2gon8aci853i99v5ya UNIQUE (code);


--
-- Name: rate_category uk_rate_category; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_category
    ADD CONSTRAINT uk_rate_category UNIQUE (branch_id, currency_code, category);


--
-- Name: transfer uk_sfe9sojfuh1x78xllwjp35iu8; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT uk_sfe9sojfuh1x78xllwjp35iu8 UNIQUE (transfer_number);


--
-- Name: receipt uk_tbqak8g0j5h1f1bbonfylcc06; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.receipt
    ADD CONSTRAINT uk_tbqak8g0j5h1f1bbonfylcc06 UNIQUE (receipt_number);


--
-- Name: license uk_ynvhomt1nm4ca2yu66iv2s33; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license
    ADD CONSTRAINT uk_ynvhomt1nm4ca2yu66iv2s33 UNIQUE (license_key);


--
-- Name: camera_config ukbgfnc2j3ocujko9i7i554qrh3; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_config
    ADD CONSTRAINT ukbgfnc2j3ocujko9i7i554qrh3 UNIQUE (branch_id, camera_id);


--
-- Name: vault_territory ukinu4rvb14h9mdm2aten5o1no7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_territory
    ADD CONSTRAINT ukinu4rvb14h9mdm2aten5o1no7 UNIQUE (company_id, name);


--
-- Name: rate_discount ukl12w1vuhvd06gd57impmwd7fj; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_discount
    ADD CONSTRAINT ukl12w1vuhvd06gd57impmwd7fj UNIQUE (workgroup_id, level);


--
-- Name: dictionary ukmaieooo8mjsran68glb26jleg; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dictionary
    ADD CONSTRAINT ukmaieooo8mjsran68glb26jleg UNIQUE (category, code);


--
-- Name: worker ukowmkg9ktgk2hpdqtlx47hhxxn; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT ukowmkg9ktgk2hpdqtlx47hhxxn UNIQUE (company_id, code);


--
-- Name: monthly_closing_summary ukqtj8v1kuxaicloyh8uk0xha1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing_summary
    ADD CONSTRAINT ukqtj8v1kuxaicloyh8uk0xha1 UNIQUE (branch_id, year_month);


--
-- Name: currency_stock uks5kmxuc76mo4kjvk09k1fh495; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_stock
    ADD CONSTRAINT uks5kmxuc76mo4kjvk09k1fh495 UNIQUE (company_id, entity_type, entity_id, currency_code);


--
-- Name: mnb_exchange_rate_cache ukukodymsn5g7gg50go7yyuvba; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_exchange_rate_cache
    ADD CONSTRAINT ukukodymsn5g7gg50go7yyuvba UNIQUE (currency_code, rate_date);


--
-- Name: daily_checklist_item uq_checklist_item_number; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist_item
    ADD CONSTRAINT uq_checklist_item_number UNIQUE (checklist_id, item_number);


--
-- Name: daily_balance uq_daily_balance_branch_date_currency; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_balance
    ADD CONSTRAINT uq_daily_balance_branch_date_currency UNIQUE (branch_id, balance_date, currency_code, company_id);


--
-- Name: daily_checklist uq_daily_checklist_branch_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist
    ADD CONSTRAINT uq_daily_checklist_branch_date UNIQUE (branch_id, checklist_date, company_id);


--
-- Name: data_collection uq_dc_branch_date_type; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_collection
    ADD CONSTRAINT uq_dc_branch_date_type UNIQUE (branch_id, collection_date, collection_type);


--
-- Name: rate_workgroup uq_rate_workgroup_company_code; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup
    ADD CONSTRAINT uq_rate_workgroup_company_code UNIQUE (company_id, code);


--
-- Name: wu_balances uq_wu_balances_branch_company; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_balances
    ADD CONSTRAINT uq_wu_balances_branch_company UNIQUE (branch_id, company_id);


--
-- Name: vault_bank_transaction vault_bank_transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_bank_transaction
    ADD CONSTRAINT vault_bank_transaction_pkey PRIMARY KEY (id);


--
-- Name: vault_collection vault_collection_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_collection
    ADD CONSTRAINT vault_collection_pkey PRIMARY KEY (id);


--
-- Name: vault_distribution_line vault_distribution_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_distribution_line
    ADD CONSTRAINT vault_distribution_line_pkey PRIMARY KEY (id);


--
-- Name: vault_distribution vault_distribution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_distribution
    ADD CONSTRAINT vault_distribution_pkey PRIMARY KEY (id);


--
-- Name: vault_territory vault_territory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_territory
    ADD CONSTRAINT vault_territory_pkey PRIMARY KEY (id);


--
-- Name: vault_transfer vault_transfer_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_transfer
    ADD CONSTRAINT vault_transfer_pkey PRIMARY KEY (id);


--
-- Name: worker_attendance worker_attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_attendance
    ADD CONSTRAINT worker_attendance_pkey PRIMARY KEY (id);


--
-- Name: worker_break worker_break_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_break
    ADD CONSTRAINT worker_break_pkey PRIMARY KEY (id);


--
-- Name: worker_commission worker_commission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_commission
    ADD CONSTRAINT worker_commission_pkey PRIMARY KEY (id);


--
-- Name: worker_competition_entry worker_competition_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_competition_entry
    ADD CONSTRAINT worker_competition_entry_pkey PRIMARY KEY (id);


--
-- Name: worker_competition worker_competition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_competition
    ADD CONSTRAINT worker_competition_pkey PRIMARY KEY (id);


--
-- Name: worker worker_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT worker_pkey PRIMARY KEY (id);


--
-- Name: worker_role_assignment worker_role_assignment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_assignment
    ADD CONSTRAINT worker_role_assignment_pkey PRIMARY KEY (id);


--
-- Name: worker_role_def worker_role_def_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_def
    ADD CONSTRAINT worker_role_def_pkey PRIMARY KEY (id);


--
-- Name: worker_role_permission worker_role_permission_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_permission
    ADD CONSTRAINT worker_role_permission_pkey PRIMARY KEY (permission_id, role_def_id);


--
-- Name: worker_session worker_session_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_session
    ADD CONSTRAINT worker_session_pkey PRIMARY KEY (id);


--
-- Name: workstation workstation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workstation
    ADD CONSTRAINT workstation_pkey PRIMARY KEY (id);


--
-- Name: wu_balances wu_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_balances
    ADD CONSTRAINT wu_balances_pkey PRIMARY KEY (id);


--
-- Name: wu_customers wu_customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_customers
    ADD CONSTRAINT wu_customers_pkey PRIMARY KEY (id);


--
-- Name: wu_transactions wu_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT wu_transactions_pkey PRIMARY KEY (id);


--
-- Name: error_logs_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_logs_created_at_idx ON public.error_logs USING btree (created_at);


--
-- Name: error_logs_fingerprint_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_logs_fingerprint_idx ON public.error_logs USING btree (fingerprint);


--
-- Name: error_logs_resolved_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_logs_resolved_idx ON public.error_logs USING btree (resolved);


--
-- Name: error_logs_severity_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX error_logs_severity_idx ON public.error_logs USING btree (severity);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_aml_report_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aml_report_company ON public.aml_report USING btree (company_id);


--
-- Name: idx_aml_report_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aml_report_created ON public.aml_report USING btree (created_at);


--
-- Name: idx_aml_report_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aml_report_customer ON public.aml_report USING btree (customer_id);


--
-- Name: idx_aml_report_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aml_report_status ON public.aml_report USING btree (status);


--
-- Name: idx_aml_report_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aml_report_type ON public.aml_report USING btree (report_type);


--
-- Name: idx_amt_branch_ym; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_amt_branch_ym ON public.archived_monthly_transaction USING btree (branch_id, year_month);


--
-- Name: idx_amt_closing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_amt_closing ON public.archived_monthly_transaction USING btree (monthly_closing_id);


--
-- Name: idx_archived_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_archived_branch ON public.archived_transactions USING btree (branch_id, archive_month);


--
-- Name: idx_archived_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_archived_company ON public.archived_transactions USING btree (company_id, archive_month);


--
-- Name: idx_archived_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_archived_date ON public.archived_transactions USING btree (original_date);


--
-- Name: idx_archived_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_archived_month ON public.archived_transactions USING btree (archive_month);


--
-- Name: idx_archived_original; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_archived_original ON public.archived_transactions USING btree (original_id);


--
-- Name: idx_audit_log_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_log_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_company_id ON public.audit_log USING btree (company_id);


--
-- Name: idx_audit_log_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_created_at ON public.audit_log USING btree (created_at);


--
-- Name: idx_audit_log_entity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_log_entity_type ON public.audit_log USING btree (entity_type);


--
-- Name: idx_auth_log_representative; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_log_representative ON public.authorization_log USING btree (representative_id);


--
-- Name: idx_auth_rep_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auth_rep_customer ON public.authorized_representative USING btree (customer_id);


--
-- Name: idx_bgg_branch_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bgg_branch_group ON public.branch_group_branches USING btree (branch_group_id);


--
-- Name: idx_branch_region_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_branch_region_code ON public.branch USING btree (region_code);


--
-- Name: idx_camera_export_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_export_branch ON public.camera_export_request USING btree (branch_id);


--
-- Name: idx_camera_export_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_export_created ON public.camera_export_request USING btree (created_at);


--
-- Name: idx_camera_export_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_export_status ON public.camera_export_request USING btree (status);


--
-- Name: idx_camera_hash_branch_camera; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_hash_branch_camera ON public.camera_segment_hash USING btree (branch_id, camera_id);


--
-- Name: idx_camera_hash_recording; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_hash_recording ON public.camera_segment_hash USING btree (recording_id);


--
-- Name: idx_camera_hash_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_hash_sequence ON public.camera_segment_hash USING btree (branch_id, camera_id, sequence_number);


--
-- Name: idx_camera_recording_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_recording_branch_date ON public.camera_recording USING btree (branch_id, start_time);


--
-- Name: idx_camera_recording_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_recording_expires ON public.camera_recording USING btree (expires_at);


--
-- Name: idx_camera_tx_link_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_tx_link_receipt ON public.camera_transaction_link USING btree (receipt_number);


--
-- Name: idx_camera_tx_link_tx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_camera_tx_link_tx ON public.camera_transaction_link USING btree (transaction_id);


--
-- Name: idx_cash_balance_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_balance_branch ON public.cash_balance USING btree (branch_id);


--
-- Name: idx_cash_balance_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_balance_currency ON public.cash_balance USING btree (currency_id);


--
-- Name: idx_cash_desk_break_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_desk_break_active ON public.cash_desk_break USING btree (is_active);


--
-- Name: idx_cash_desk_break_desk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_desk_break_desk ON public.cash_desk_break USING btree (cash_desk_id);


--
-- Name: idx_cash_register_event_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_register_event_branch ON public.cash_register_event USING btree (branch_id);


--
-- Name: idx_cash_register_event_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_register_event_timestamp ON public.cash_register_event USING btree (event_timestamp);


--
-- Name: idx_cash_register_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cash_register_event_type ON public.cash_register_event USING btree (event_type);


--
-- Name: idx_ci_collection; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ci_collection ON public.collected_inventory USING btree (data_collection_id);


--
-- Name: idx_ci_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ci_currency ON public.collected_inventory USING btree (currency_code);


--
-- Name: idx_circ_ack_circular; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circ_ack_circular ON public.circular_acknowledgment USING btree (circular_id);


--
-- Name: idx_circ_ack_unacked; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circ_ack_unacked ON public.circular_acknowledgment USING btree (circular_id, worker_id);


--
-- Name: idx_circ_ack_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circ_ack_worker ON public.circular_acknowledgment USING btree (worker_id);


--
-- Name: idx_circular_archived; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circular_archived ON public.circular USING btree (archived, company_id);


--
-- Name: idx_circular_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circular_category ON public.circular USING btree (company_id, category);


--
-- Name: idx_circular_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circular_company ON public.circular USING btree (company_id);


--
-- Name: idx_circular_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circular_created_by ON public.circular USING btree (created_by_id);


--
-- Name: idx_circular_urgent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_circular_urgent ON public.circular USING btree (urgent);


--
-- Name: idx_closing_wizard_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_closing_wizard_branch ON public.closing_wizard USING btree (branch_id);


--
-- Name: idx_closing_wizard_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_closing_wizard_status ON public.closing_wizard USING btree (wizard_status);


--
-- Name: idx_closing_wizard_step_wizard; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_closing_wizard_step_wizard ON public.closing_wizard_step USING btree (wizard_id);


--
-- Name: idx_coc_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coc_branch ON public.chain_of_custody_record USING btree (branch_id);


--
-- Name: idx_coc_export; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coc_export ON public.chain_of_custody_record USING btree (export_request_id);


--
-- Name: idx_coc_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coc_timestamp ON public.chain_of_custody_record USING btree (event_timestamp);


--
-- Name: idx_comm_calc_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comm_calc_branch ON public.commission_calculation USING btree (branch_id);


--
-- Name: idx_comm_calc_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comm_calc_period ON public.commission_calculation USING btree (period);


--
-- Name: idx_comm_calc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comm_calc_status ON public.commission_calculation USING btree (status);


--
-- Name: idx_comm_rule_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comm_rule_company ON public.commission_rule USING btree (company_id);


--
-- Name: idx_comm_rule_tier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comm_rule_tier ON public.commission_rule USING btree (tier);


--
-- Name: idx_comp_entry_competition; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comp_entry_competition ON public.worker_competition_entry USING btree (competition_id);


--
-- Name: idx_comp_entry_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comp_entry_worker ON public.worker_competition_entry USING btree (worker_id);


--
-- Name: idx_competition_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competition_status ON public.worker_competition USING btree (status);


--
-- Name: idx_competitor_rate_comp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_competitor_rate_comp ON public.competitor_rates USING btree (competitor_id);


--
-- Name: idx_ct_collection; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ct_collection ON public.collected_transaction USING btree (data_collection_id);


--
-- Name: idx_ct_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ct_currency ON public.collected_transaction USING btree (currency_code);


--
-- Name: idx_ct_original; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ct_original ON public.collected_transaction USING btree (original_transaction_id);


--
-- Name: idx_currency_stock_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_currency_stock_entity ON public.currency_stock USING btree (entity_type, entity_id, currency_code);


--
-- Name: idx_customer_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_company ON public.customer USING btree (company_id);


--
-- Name: idx_customer_document; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_customer_document ON public.customer USING btree (document_number);


--
-- Name: idx_daily_balance_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_balance_branch_date ON public.daily_balance USING btree (branch_id, balance_date);


--
-- Name: idx_daily_balance_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_balance_company ON public.daily_balance USING btree (company_id, balance_date);


--
-- Name: idx_daily_balance_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_balance_currency ON public.daily_balance USING btree (currency_code);


--
-- Name: idx_daily_balance_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_balance_date ON public.daily_balance USING btree (balance_date);


--
-- Name: idx_daily_checklist_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_checklist_branch_date ON public.daily_checklist USING btree (branch_id, checklist_date);


--
-- Name: idx_daily_checklist_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_checklist_company ON public.daily_checklist USING btree (company_id);


--
-- Name: idx_daily_checklist_item_checklist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_checklist_item_checklist ON public.daily_checklist_item USING btree (checklist_id);


--
-- Name: idx_daily_report_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_report_branch ON public.daily_report USING btree (branch_id);


--
-- Name: idx_daily_report_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_report_date ON public.daily_report USING btree (report_date);


--
-- Name: idx_daily_session_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_session_branch ON public.daily_session USING btree (branch_id);


--
-- Name: idx_daily_session_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_session_date ON public.daily_session USING btree (session_date);


--
-- Name: idx_darius_line_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_darius_line_branch ON public.darius_report_line USING btree (branch_id);


--
-- Name: idx_darius_line_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_darius_line_report ON public.darius_report_line USING btree (report_id);


--
-- Name: idx_darius_report_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_darius_report_company ON public.darius_daily_report USING btree (company_id);


--
-- Name: idx_darius_report_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_darius_report_date ON public.darius_daily_report USING btree (report_date);


--
-- Name: idx_darius_report_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_darius_report_status ON public.darius_daily_report USING btree (status);


--
-- Name: idx_data_import_jobs_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_import_jobs_branch ON public.data_import_jobs USING btree (branch_id);


--
-- Name: idx_data_import_jobs_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_import_jobs_status ON public.data_import_jobs USING btree (status);


--
-- Name: idx_data_import_jobs_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_data_import_jobs_type ON public.data_import_jobs USING btree (import_type);


--
-- Name: idx_dc_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dc_branch_date ON public.data_collection USING btree (branch_id, collection_date);


--
-- Name: idx_dc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dc_status ON public.data_collection USING btree (status);


--
-- Name: idx_dc_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dc_type ON public.data_collection USING btree (collection_type);


--
-- Name: idx_decade_line_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_decade_line_report ON public.decade_report_line USING btree (decade_report_id);


--
-- Name: idx_decade_report_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_decade_report_branch ON public.decade_report USING btree (branch_id);


--
-- Name: idx_decade_report_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_decade_report_year ON public.decade_report USING btree (year);


--
-- Name: idx_denom_balance_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_balance_category ON public.denomination_balance USING btree (cash_desk_id, updated_at, denomination_category);


--
-- Name: idx_denom_balance_denomination; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_balance_denomination ON public.denomination_balance USING btree (denomination_id);


--
-- Name: idx_denom_balance_desk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_balance_desk ON public.denomination_balance USING btree (cash_desk_id);


--
-- Name: idx_denom_count_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_count_branch ON public.denomination_count USING btree (branch_id);


--
-- Name: idx_denom_count_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_count_category ON public.denomination_count USING btree (branch_id, created_at, denomination_category);


--
-- Name: idx_denom_count_session; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denom_count_session ON public.denomination_count USING btree (session_id);


--
-- Name: idx_denomination_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denomination_branch ON public.denomination USING btree (branch_id);


--
-- Name: idx_denomination_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_denomination_currency ON public.denomination USING btree (currency_id);


--
-- Name: idx_document_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_document_company_id ON public.document USING btree (company_id);


--
-- Name: idx_evening_sync_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_evening_sync_branch_date ON public.evening_sync_log USING btree (branch_id, sync_date);


--
-- Name: idx_exchange_rate_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exchange_rate_company ON public.exchange_rate USING btree (company_id);


--
-- Name: idx_exchange_rate_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exchange_rate_currency ON public.exchange_rate USING btree (currency_id);


--
-- Name: idx_exchange_rate_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_exchange_rate_date ON public.exchange_rate USING btree (valid_date, valid_time);


--
-- Name: idx_fee_bracket_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fee_bracket_company ON public.handling_fee_bracket USING btree (company_id);


--
-- Name: idx_ftp_sync_log_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ftp_sync_log_branch ON public.ftp_sync_log USING btree (branch_id);


--
-- Name: idx_ftp_sync_log_started; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ftp_sync_log_started ON public.ftp_sync_log USING btree (started_at);


--
-- Name: idx_ftp_sync_log_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ftp_sync_log_status ON public.ftp_sync_log USING btree (status);


--
-- Name: idx_hf_decade_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hf_decade_branch ON public.handling_fee_decade_report USING btree (branch_id);


--
-- Name: idx_hf_decade_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hf_decade_year ON public.handling_fee_decade_report USING btree (year);


--
-- Name: idx_hf_transaction_tx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hf_transaction_tx ON public.handling_fee_transaction USING btree (transaction_id);


--
-- Name: idx_initfee_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_initfee_company ON public.initial_fee_config USING btree (company_id);


--
-- Name: idx_inv_mov_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_currency ON public.inventory_movement USING btree (currency_id);


--
-- Name: idx_inv_mov_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_date ON public.inventory_movement USING btree (movement_date);


--
-- Name: idx_inv_mov_from_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_from_branch ON public.inventory_movement USING btree (from_branch_id);


--
-- Name: idx_inv_mov_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_status ON public.inventory_movement USING btree (status);


--
-- Name: idx_inv_mov_to_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_to_branch ON public.inventory_movement USING btree (to_branch_id);


--
-- Name: idx_inv_mov_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_mov_type ON public.inventory_movement USING btree (movement_type);


--
-- Name: idx_inv_regen_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_regen_branch ON public.inventory_regeneration USING btree (branch_id);


--
-- Name: idx_inv_sum_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_sum_branch ON public.inventory_summary USING btree (branch_id);


--
-- Name: idx_inv_sum_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_sum_currency ON public.inventory_summary USING btree (currency_id);


--
-- Name: idx_inv_sum_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_sum_date ON public.inventory_summary USING btree (summary_date);


--
-- Name: idx_led_display_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_led_display_branch ON public.led_display USING btree (branch_id);


--
-- Name: idx_led_display_branch_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_led_display_branch_unique ON public.led_display_config USING btree (branch_id);


--
-- Name: idx_led_display_config_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_led_display_config_branch ON public.led_display_config USING btree (branch_id);


--
-- Name: idx_material_receipt_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_material_receipt_company ON public.material_receipt USING btree (company_id);


--
-- Name: idx_material_receipt_line_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_material_receipt_line_receipt ON public.material_receipt_line USING btree (receipt_id);


--
-- Name: idx_material_receipt_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_material_receipt_number ON public.material_receipt USING btree (company_id, receipt_number);


--
-- Name: idx_material_receipt_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_material_receipt_type ON public.material_receipt USING btree (company_id, receipt_type);


--
-- Name: idx_mnb_line_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_line_currency ON public.mnb_report_line USING btree (currency_code);


--
-- Name: idx_mnb_line_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_line_report ON public.mnb_report_line USING btree (mnb_report_id);


--
-- Name: idx_mnb_rate_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_rate_currency ON public.mnb_exchange_rate_cache USING btree (currency_code);


--
-- Name: idx_mnb_rate_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_rate_date ON public.mnb_exchange_rate_cache USING btree (rate_date);


--
-- Name: idx_mnb_report_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_report_branch_date ON public.mnb_report USING btree (branch_id, report_date);


--
-- Name: idx_mnb_report_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_report_status ON public.mnb_report USING btree (status);


--
-- Name: idx_mnb_report_type_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mnb_report_type_date ON public.mnb_report USING btree (report_type, report_date);


--
-- Name: idx_monthly_closing_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monthly_closing_branch ON public.monthly_closing USING btree (branch_id);


--
-- Name: idx_monthly_closing_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monthly_closing_company ON public.monthly_closing USING btree (company_id);


--
-- Name: idx_monthly_closing_period; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monthly_closing_period ON public.monthly_closing USING btree (year_month);


--
-- Name: idx_monthly_closing_yearmonth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monthly_closing_yearmonth ON public.monthly_closing_summary USING btree (year_month);


--
-- Name: idx_nav_closing_branch_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_nav_closing_branch_date ON public.nav_closing USING btree (branch_id, closing_date);


--
-- Name: idx_nav_closing_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_nav_closing_status ON public.nav_closing USING btree (status);


--
-- Name: idx_nav_closing_type_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_nav_closing_type_date ON public.nav_closing USING btree (closing_type, closing_date);


--
-- Name: idx_nav_line_closing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_nav_line_closing ON public.nav_closing_line USING btree (nav_closing_id);


--
-- Name: idx_nav_line_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_nav_line_currency ON public.nav_closing_line USING btree (currency_code);


--
-- Name: idx_notification_entity_type_id_ntype; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_entity_type_id_ntype ON public.notification USING btree (entity_type, entity_id, notification_type) WHERE (entity_type IS NOT NULL);


--
-- Name: idx_notification_user_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_user_created ON public.notification USING btree (user_id, created_at DESC);


--
-- Name: idx_notification_user_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_user_read ON public.notification USING btree (user_id, is_read);


--
-- Name: idx_packaging_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_packaging_branch ON public.packaging_record USING btree (branch_id);


--
-- Name: idx_packaging_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_packaging_date ON public.packaging_record USING btree (packaging_date);


--
-- Name: idx_police_request_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_police_request_date ON public.police_request USING btree (request_date);


--
-- Name: idx_police_request_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_police_request_status ON public.police_request USING btree (status);


--
-- Name: idx_profit_log_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profit_log_branch ON public.profit_log USING btree (branch_id, created_at);


--
-- Name: idx_profit_log_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_profit_log_company ON public.profit_log USING btree (company_id, created_at);


--
-- Name: idx_rate_approval_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_approval_branch ON public.rate_approval USING btree (branch_id);


--
-- Name: idx_rate_approval_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_approval_status ON public.rate_approval USING btree (status);


--
-- Name: idx_rate_category_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_category_branch ON public.rate_category USING btree (branch_id);


--
-- Name: idx_rate_category_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_category_currency ON public.rate_category USING btree (currency_code);


--
-- Name: idx_rate_discount_company_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_discount_company_id ON public.rate_discount USING btree (company_id);


--
-- Name: idx_rate_history_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_history_branch ON public.rate_history USING btree (branch_id);


--
-- Name: idx_rate_history_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_history_company ON public.rate_history USING btree (company_id);


--
-- Name: idx_rate_history_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_history_currency ON public.rate_history USING btree (currency_code);


--
-- Name: idx_rate_history_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_history_dates ON public.rate_history USING btree (effective_from, effective_to);


--
-- Name: idx_rate_publication_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_publication_company ON public.rate_publication USING btree (company_id);


--
-- Name: idx_rate_publication_wg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_publication_wg ON public.rate_publication USING btree (workgroup_id);


--
-- Name: idx_rate_template_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_template_company ON public.rate_template USING btree (company_id);


--
-- Name: idx_rate_template_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_template_currency ON public.rate_template USING btree (currency_id);


--
-- Name: idx_rate_template_wg_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_template_wg_status ON public.rate_template USING btree (workgroup_id, status);


--
-- Name: idx_rate_workgroup_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rate_workgroup_company ON public.rate_workgroup USING btree (company_id);


--
-- Name: idx_receipt_seq_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_receipt_seq_branch ON public.receipt_sequence USING btree (branch_id);


--
-- Name: idx_reservation_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_branch ON public.reservation USING btree (branch_id);


--
-- Name: idx_reservation_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_company ON public.reservation USING btree (company_id);


--
-- Name: idx_reservation_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_customer ON public.reservation USING btree (customer_id);


--
-- Name: idx_reservation_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_expires ON public.reservation USING btree (expires_at);


--
-- Name: idx_reservation_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_receipt ON public.reservation USING btree (receipt_number);


--
-- Name: idx_reservation_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_reservation_status ON public.reservation USING btree (status);


--
-- Name: idx_rounding_rule_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rounding_rule_currency ON public.rounding_rule USING btree (currency_code);


--
-- Name: idx_sanction_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sanction_active ON public.sanction_entries USING btree (active);


--
-- Name: idx_sanction_document_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sanction_document_number ON public.sanction_entries USING btree (document_number);


--
-- Name: idx_sanction_full_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sanction_full_name ON public.sanction_entries USING btree (full_name);


--
-- Name: idx_sanction_list_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sanction_list_type ON public.sanction_entries USING btree (list_type);


--
-- Name: idx_scanned_document_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scanned_document_customer ON public.scanned_document USING btree (customer_id);


--
-- Name: idx_scanned_document_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scanned_document_transaction ON public.scanned_document USING btree (transaction_id);


--
-- Name: idx_scanned_document_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scanned_document_type ON public.scanned_document USING btree (document_type);


--
-- Name: idx_screening_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_screening_log_created ON public.sanction_screening_log USING btree (created_at);


--
-- Name: idx_screening_log_result; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_screening_log_result ON public.sanction_screening_log USING btree (result);


--
-- Name: idx_screening_log_screened_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_screening_log_screened_name ON public.sanction_screening_log USING btree (screened_name);


--
-- Name: idx_screening_log_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_screening_log_worker ON public.sanction_screening_log USING btree (worker_id);


--
-- Name: idx_seal_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seal_branch ON public.seal_number USING btree (branch_id);


--
-- Name: idx_seal_tracking_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seal_tracking_company ON public.seal_tracking USING btree (company_id);


--
-- Name: idx_seal_tracking_company_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seal_tracking_company_status ON public.seal_tracking USING btree (company_id, transit_status) WHERE ((transit_status)::text = ANY ((ARRAY['SEALED'::character varying, 'IN_TRANSIT'::character varying])::text[]));


--
-- Name: idx_seal_tracking_transfer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_seal_tracking_transfer ON public.seal_tracking USING btree (transfer_type, transfer_id);


--
-- Name: idx_shipment_request_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_shipment_request_status ON public.shipment_request USING btree (status);


--
-- Name: idx_stock_correction_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_correction_company ON public.stock_correction USING btree (company_id);


--
-- Name: idx_stock_correction_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_stock_correction_entity ON public.stock_correction USING btree (company_id, entity_type, entity_id);


--
-- Name: idx_storno_approval_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_storno_approval_branch ON public.storno_approval USING btree (branch_id);


--
-- Name: idx_storno_approval_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_storno_approval_transaction ON public.storno_approval USING btree (transaction_id);


--
-- Name: idx_storno_approval_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_storno_approval_worker ON public.storno_approval USING btree (worker_id);


--
-- Name: idx_sync_inbox_received_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_inbox_received_at ON public.sync_inbox USING btree (received_at);


--
-- Name: idx_sync_inbox_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_inbox_status ON public.sync_inbox USING btree (status);


--
-- Name: idx_sync_outbox_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_outbox_created_at ON public.sync_outbox USING btree (created_at);


--
-- Name: idx_sync_outbox_status_next_retry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_outbox_status_next_retry ON public.sync_outbox USING btree (status, next_retry_at);


--
-- Name: idx_token_blacklist_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_token_blacklist_expires_at ON public.token_blacklist USING btree (expires_at);


--
-- Name: idx_token_blacklist_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_token_blacklist_token_id ON public.token_blacklist USING btree (token_id);


--
-- Name: idx_transaction_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_branch ON public.transaction USING btree (branch_id);


--
-- Name: idx_transaction_branch_date_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_branch_date_status ON public.transaction USING btree (branch_id, transaction_date, status);


--
-- Name: idx_transaction_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_company ON public.transaction USING btree (company_id);


--
-- Name: idx_transaction_company_customer_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_company_customer_date ON public.transaction USING btree (company_id, customer_id, transaction_date);


--
-- Name: idx_transaction_company_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_company_date ON public.transaction USING btree (company_id, transaction_date);


--
-- Name: idx_transaction_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_date ON public.transaction USING btree (transaction_date);


--
-- Name: idx_transaction_linked_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_linked_receipt ON public.transaction USING btree (linked_receipt_number);


--
-- Name: idx_transaction_original_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_original_id ON public.transaction USING btree (original_transaction_id) WHERE (original_transaction_id IS NOT NULL);


--
-- Name: idx_transaction_receipt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_receipt ON public.transaction USING btree (receipt_number);


--
-- Name: idx_transaction_worker; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transaction_worker ON public.transaction USING btree (worker_id);


--
-- Name: idx_transfer_doc_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_doc_company ON public.transfer_document USING btree (company_id, created_at);


--
-- Name: idx_transfer_doc_courier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_doc_courier ON public.transfer_document USING btree (courier_id, status);


--
-- Name: idx_transfer_doc_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_transfer_doc_status ON public.transfer_document USING btree (status);


--
-- Name: idx_translation_module; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_translation_module ON public.translation USING btree (module);


--
-- Name: idx_txline_currency; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_txline_currency ON public.transaction_line USING btree (currency_id);


--
-- Name: idx_txline_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_txline_transaction ON public.transaction_line USING btree (transaction_id);


--
-- Name: idx_vault_bank_tx_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_bank_tx_company ON public.vault_bank_transaction USING btree (company_id);


--
-- Name: idx_vault_bank_tx_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_bank_tx_date ON public.vault_bank_transaction USING btree (company_id, created_at);


--
-- Name: idx_vault_bank_tx_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_bank_tx_status ON public.vault_bank_transaction USING btree (company_id, status);


--
-- Name: idx_vault_bank_tx_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_bank_tx_type ON public.vault_bank_transaction USING btree (company_id, transaction_type);


--
-- Name: idx_vault_collection_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_collection_branch ON public.vault_collection USING btree (company_id, source_branch_code);


--
-- Name: idx_vault_collection_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_collection_company ON public.vault_collection USING btree (company_id);


--
-- Name: idx_vault_collection_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_collection_status ON public.vault_collection USING btree (company_id, status);


--
-- Name: idx_vault_dist_line_dist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_dist_line_dist ON public.vault_distribution_line USING btree (distribution_id);


--
-- Name: idx_vault_distribution_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_distribution_company ON public.vault_distribution USING btree (company_id);


--
-- Name: idx_vault_distribution_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_distribution_status ON public.vault_distribution USING btree (company_id, status);


--
-- Name: idx_vault_transfer_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_transfer_company ON public.vault_transfer USING btree (company_id);


--
-- Name: idx_vault_transfer_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_transfer_date ON public.vault_transfer USING btree (company_id, created_at);


--
-- Name: idx_vault_transfer_number; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_transfer_number ON public.vault_transfer USING btree (company_id, transfer_number);


--
-- Name: idx_vault_transfer_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vault_transfer_status ON public.vault_transfer USING btree (company_id, status);


--
-- Name: idx_wu_balance_branch_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wu_balance_branch_company ON public.wu_balances USING btree (branch_id, company_id);


--
-- Name: idx_wu_transactions_branch; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wu_transactions_branch ON public.wu_transactions USING btree (branch_id);


--
-- Name: idx_wu_transactions_company; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wu_transactions_company ON public.wu_transactions USING btree (company_id);


--
-- Name: idx_wu_transactions_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wu_transactions_date ON public.wu_transactions USING btree (transaction_date);


--
-- Name: idx_wu_transactions_mtcn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_wu_transactions_mtcn ON public.wu_transactions USING btree (mtcn);


--
-- Name: uk_branch_group_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_branch_group_code ON public.branch_group USING btree (code);


--
-- Name: uk_currency_group_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_currency_group_code ON public.currency_group USING btree (code);


--
-- Name: uk_fee_discount_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_fee_discount_code ON public.fee_discount USING btree (code);


--
-- Name: uk_fee_type_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_fee_type_code ON public.fee_type USING btree (code);


--
-- Name: uk_handover_sheet_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_handover_sheet_number ON public.handover_sheet USING btree (sheet_number);


--
-- Name: uk_organization_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_organization_code ON public.organization USING btree (code);


--
-- Name: uk_pos_terminal_terminal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_pos_terminal_terminal_id ON public.pos_terminal USING btree (terminal_id);


--
-- Name: uk_receipt_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_receipt_number ON public.receipt USING btree (receipt_number);


--
-- Name: uk_shipment_request_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_shipment_request_number ON public.shipment_request USING btree (request_number);


--
-- Name: uk_system_parameter_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_system_parameter_key ON public.system_parameter USING btree (parameter_key);


--
-- Name: uk_worker_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_worker_email ON public.worker USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: uk_workstation_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_workstation_code ON public.workstation USING btree (code);


--
-- Name: uq_seal_tracking_company_seal; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_seal_tracking_company_seal ON public.seal_tracking USING btree (company_id, seal_number);


--
-- Name: uq_wu_customer_company_name_idnum; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_wu_customer_company_name_idnum ON public.wu_customers USING btree (company_id, last_name, first_name, id_number) WHERE ((id_number IS NOT NULL) AND ((id_number)::text <> ''::text));


--
-- Name: uq_wu_customers_name_document; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_wu_customers_name_document ON public.wu_customers USING btree (last_name, first_name, id_number) WHERE (id_number IS NOT NULL);


--
-- Name: circular_acknowledgment circular_acknowledgment_circular_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular_acknowledgment
    ADD CONSTRAINT circular_acknowledgment_circular_id_fkey FOREIGN KEY (circular_id) REFERENCES public.circular(id) ON DELETE CASCADE;


--
-- Name: daily_checklist daily_checklist_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist
    ADD CONSTRAINT daily_checklist_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: daily_checklist daily_checklist_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist
    ADD CONSTRAINT daily_checklist_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: daily_checklist_item daily_checklist_item_checklist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_checklist_item
    ADD CONSTRAINT daily_checklist_item_checklist_id_fkey FOREIGN KEY (checklist_id) REFERENCES public.daily_checklist(id) ON DELETE CASCADE;


--
-- Name: decade_report_line decade_report_line_decade_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report_line
    ADD CONSTRAINT decade_report_line_decade_report_id_fkey FOREIGN KEY (decade_report_id) REFERENCES public.decade_report(id) ON DELETE CASCADE;


--
-- Name: branch fk14f9k065wqeubl6tl0gdumcp5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT fk14f9k065wqeubl6tl0gdumcp5 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: worker fk1856lfikvij3xma8ourmkw8d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT fk1856lfikvij3xma8ourmkw8d FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: aml_report fk1dor9bgxil7bs8dwxdsrwklnw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aml_report
    ADD CONSTRAINT fk1dor9bgxil7bs8dwxdsrwklnw FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: transfer fk1i7ggk2voycuivq9f0mkruejx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT fk1i7ggk2voycuivq9f0mkruejx FOREIGN KEY (to_worker_id) REFERENCES public.worker(id);


--
-- Name: inventory_regeneration fk1op44pb8qwuvj774sqce112lv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_regeneration
    ADD CONSTRAINT fk1op44pb8qwuvj774sqce112lv FOREIGN KEY (regenerated_by) REFERENCES public.worker(id);


--
-- Name: transaction fk1t6qrqj815ftox3wbme7dcb2t; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT fk1t6qrqj815ftox3wbme7dcb2t FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: reservation fk1wksaeptng6kdfw5ro7ierplg; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT fk1wksaeptng6kdfw5ro7ierplg FOREIGN KEY (supervisor_worker_id) REFERENCES public.worker(id);


--
-- Name: email_account fk2l8us96rhbpbdbntqhl14dew4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT fk2l8us96rhbpbdbntqhl14dew4 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: initial_fee_config fk2tvodc8n46w9k7fx1loo97ge3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initial_fee_config
    ADD CONSTRAINT fk2tvodc8n46w9k7fx1loo97ge3 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: camera_transaction_link fk2y0xrcttwe5yhqh9s6h5af0r0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_transaction_link
    ADD CONSTRAINT fk2y0xrcttwe5yhqh9s6h5af0r0 FOREIGN KEY (recording_id) REFERENCES public.camera_recording(id);


--
-- Name: inventory_movement fk30d8yogioe8fubwsaf1f73x19; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fk30d8yogioe8fubwsaf1f73x19 FOREIGN KEY (from_branch_id) REFERENCES public.branch(id);


--
-- Name: transfer_document fk35nqywhjv3q9q40ncp5erjymx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document
    ADD CONSTRAINT fk35nqywhjv3q9q40ncp5erjymx FOREIGN KEY (receiver_id) REFERENCES public.worker(id);


--
-- Name: wu_transactions fk35regpv835ry265jyut8ilux7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT fk35regpv835ry265jyut8ilux7 FOREIGN KEY (wu_customer_id) REFERENCES public.wu_customers(id);


--
-- Name: worker_role_assignment fk3lmfkc5no6ne8cgsrnseu3v12; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_assignment
    ADD CONSTRAINT fk3lmfkc5no6ne8cgsrnseu3v12 FOREIGN KEY (role_def_id) REFERENCES public.worker_role_def(id);


--
-- Name: employee fk3ygtr6ktpgwioh03vhtj6kxaw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk3ygtr6ktpgwioh03vhtj6kxaw FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: daily_session fk3yq5vk01cjybysh133lblt8gr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session
    ADD CONSTRAINT fk3yq5vk01cjybysh133lblt8gr FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: reservation fk41v6ueo0hiran65w8y1cta2c2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT fk41v6ueo0hiran65w8y1cta2c2 FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: trade fk47gfq4rln4hbtpkdwuswp3mo0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade
    ADD CONSTRAINT fk47gfq4rln4hbtpkdwuswp3mo0 FOREIGN KEY (from_branch_id) REFERENCES public.branch(id);


--
-- Name: aml_report fk4hv0o4di9hf8td6mx6t9nvgpx; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aml_report
    ADD CONSTRAINT fk4hv0o4di9hf8td6mx6t9nvgpx FOREIGN KEY (transaction_id) REFERENCES public.transaction(id);


--
-- Name: closing_wizard fk4it5vhuckhnq7qgngty84t58r; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard
    ADD CONSTRAINT fk4it5vhuckhnq7qgngty84t58r FOREIGN KEY (started_by_worker_id) REFERENCES public.worker(id);


--
-- Name: rate_workgroup_branch fk4k60flrhf7ja23rpmuha58iu2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup_branch
    ADD CONSTRAINT fk4k60flrhf7ja23rpmuha58iu2 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: inventory_movement fk51sk1dyhp96yvr0s7mplyvuct; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fk51sk1dyhp96yvr0s7mplyvuct FOREIGN KEY (approved_by_id) REFERENCES public.worker(id);


--
-- Name: exchange_rate fk55yjrct1osthhit3wsdy63omr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate
    ADD CONSTRAINT fk55yjrct1osthhit3wsdy63omr FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: worker_session fk5hbcx1hhjndf9ct7qc6215vem; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_session
    ADD CONSTRAINT fk5hbcx1hhjndf9ct7qc6215vem FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: nav_closing fk5hcd7uoailyihpw9r0ky1pp6k; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_closing
    ADD CONSTRAINT fk5hcd7uoailyihpw9r0ky1pp6k FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: employee fk5v50ed2bjh60n1gc7ifuxmgf4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT fk5v50ed2bjh60n1gc7ifuxmgf4 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: transaction fk663p7ti35m6atop4eipkfb0t; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT fk663p7ti35m6atop4eipkfb0t FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: denomination_balance fk66c0yuujhg6drbu3paqwsgvg2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination_balance
    ADD CONSTRAINT fk66c0yuujhg6drbu3paqwsgvg2 FOREIGN KEY (denomination_id) REFERENCES public.denomination(id);


--
-- Name: closing_wizard fk66tpw0fvureaoucvpo9dvhqx6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard
    ADD CONSTRAINT fk66tpw0fvureaoucvpo9dvhqx6 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: transaction fk67x0jrs2q3l7neymsrgys54ip; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT fk67x0jrs2q3l7neymsrgys54ip FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: closing_wizard_step fk6bhep8r9t3ro6ufpspd6lpr91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard_step
    ADD CONSTRAINT fk6bhep8r9t3ro6ufpspd6lpr91 FOREIGN KEY (wizard_id) REFERENCES public.closing_wizard(id);


--
-- Name: daily_session fk6rqtg3k7a2puktlc5w72k4iuy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session
    ADD CONSTRAINT fk6rqtg3k7a2puktlc5w72k4iuy FOREIGN KEY (opened_by_worker_id) REFERENCES public.worker(id);


--
-- Name: wu_customers fk6tb66h65p2xmuihasvriojdo3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_customers
    ADD CONSTRAINT fk6tb66h65p2xmuihasvriojdo3 FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: branch fk7nhs5640vcyrq7u39odc0jsvd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT fk7nhs5640vcyrq7u39odc0jsvd FOREIGN KEY (branch_type_did) REFERENCES public.dictionary(id);


--
-- Name: daily_report fk7om7n2xkwp4rpre6iduwwxnki; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_report
    ADD CONSTRAINT fk7om7n2xkwp4rpre6iduwwxnki FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: branch fk7v1qsurejgkn41dr03anjgb1x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT fk7v1qsurejgkn41dr03anjgb1x FOREIGN KEY (parent_branch_id) REFERENCES public.branch(id);


--
-- Name: inventory_regeneration fk7wrx2sboxdwxf7eq1iwlhqpk0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_regeneration
    ADD CONSTRAINT fk7wrx2sboxdwxf7eq1iwlhqpk0 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: mnb_report_line fk7ygfjj1dows9xq12arvkofsrr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_report_line
    ADD CONSTRAINT fk7ygfjj1dows9xq12arvkofsrr FOREIGN KEY (mnb_report_id) REFERENCES public.mnb_report(id);


--
-- Name: cash_register_event fk8nbub0ocjb23bmgdf2goqqxe7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_register_event
    ADD CONSTRAINT fk8nbub0ocjb23bmgdf2goqqxe7 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: currency_stock fk8yv5dtyir00vru3mr3w4l9nvc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_stock
    ADD CONSTRAINT fk8yv5dtyir00vru3mr3w4l9nvc FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: email_cache fk90ige8ir5gkkvyqpfhsrs0wxo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_cache
    ADD CONSTRAINT fk90ige8ir5gkkvyqpfhsrs0wxo FOREIGN KEY (email_account_id) REFERENCES public.email_account(id);


--
-- Name: transfer fk97jwc2s2eni3nvuqujp6qk87o; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT fk97jwc2s2eni3nvuqujp6qk87o FOREIGN KEY (from_branch_id) REFERENCES public.branch(id);


--
-- Name: trade fk98pk4telc0fdeqwr5bax9x3pb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.trade
    ADD CONSTRAINT fk98pk4telc0fdeqwr5bax9x3pb FOREIGN KEY (to_branch_id) REFERENCES public.branch(id);


--
-- Name: storno_approval fk9kj1sqk9j3dqbgs7trb3emrwj; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT fk9kj1sqk9j3dqbgs7trb3emrwj FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: cash_balance fk9v8i1tvg6y14h2bv8uo5ouea3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance
    ADD CONSTRAINT fk9v8i1tvg6y14h2bv8uo5ouea3 FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: camera_export_request fk_camera_export_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_export_request
    ADD CONSTRAINT fk_camera_export_branch FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: camera_segment_hash fk_camera_hash_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_segment_hash
    ADD CONSTRAINT fk_camera_hash_branch FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: camera_segment_hash fk_camera_hash_recording; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_segment_hash
    ADD CONSTRAINT fk_camera_hash_recording FOREIGN KEY (recording_id) REFERENCES public.camera_recording(id);


--
-- Name: chain_of_custody_record fk_coc_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain_of_custody_record
    ADD CONSTRAINT fk_coc_branch FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: chain_of_custody_record fk_coc_export; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chain_of_custody_record
    ADD CONSTRAINT fk_coc_export FOREIGN KEY (export_request_id) REFERENCES public.camera_export_request(id);


--
-- Name: competitor_rates fk_comp_rate_competitor; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_rates
    ADD CONSTRAINT fk_comp_rate_competitor FOREIGN KEY (competitor_id) REFERENCES public.competitor(id);


--
-- Name: competitor_rates fk_comp_rate_currency; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.competitor_rates
    ADD CONSTRAINT fk_comp_rate_currency FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: darius_report_line fk_darius_line_branch; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_report_line
    ADD CONSTRAINT fk_darius_line_branch FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: darius_report_line fk_darius_line_report; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_report_line
    ADD CONSTRAINT fk_darius_line_report FOREIGN KEY (report_id) REFERENCES public.darius_daily_report(id) ON DELETE CASCADE;


--
-- Name: darius_daily_report fk_darius_report_company; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.darius_daily_report
    ADD CONSTRAINT fk_darius_report_company FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_discount fk_rate_discount_company; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_discount
    ADD CONSTRAINT fk_rate_discount_company FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_publication fk_rate_publication_company; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_publication
    ADD CONSTRAINT fk_rate_publication_company FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_publication fk_rate_publication_workgroup; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_publication
    ADD CONSTRAINT fk_rate_publication_workgroup FOREIGN KEY (workgroup_id) REFERENCES public.rate_workgroup(id);


--
-- Name: rate_template fk_rate_template_company; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_template
    ADD CONSTRAINT fk_rate_template_company FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_workgroup fk_rate_workgroup_company; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup
    ADD CONSTRAINT fk_rate_workgroup_company FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: wu_transactions fk_wu_transactions_reversed; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT fk_wu_transactions_reversed FOREIGN KEY (reversed_transaction_id) REFERENCES public.wu_transactions(id) ON DELETE SET NULL;


--
-- Name: storno_approval fka091bj9n9g8lxc6xcs7crff33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT fka091bj9n9g8lxc6xcs7crff33 FOREIGN KEY (approval_status_did) REFERENCES public.dictionary(id);


--
-- Name: email_account fka3irmae6dx30cj3g27pywkimh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT fka3irmae6dx30cj3g27pywkimh FOREIGN KEY (configured_by_worker_id) REFERENCES public.worker(id);


--
-- Name: worker_session fka4pxx718jnwqwiyc5rbyqxect; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_session
    ADD CONSTRAINT fka4pxx718jnwqwiyc5rbyqxect FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: inventory_movement fka5jkev2eso3j7bg6ppxj89nwl; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fka5jkev2eso3j7bg6ppxj89nwl FOREIGN KEY (received_by_id) REFERENCES public.worker(id);


--
-- Name: role_permission fka6jx8n8xkesmjmv6jqug6bg68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT fka6jx8n8xkesmjmv6jqug6bg68 FOREIGN KEY (role_id) REFERENCES public.role(id);


--
-- Name: inventory_summary fkante0g9ydcw0o0oct9fdx6qwt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_summary
    ADD CONSTRAINT fkante0g9ydcw0o0oct9fdx6qwt FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: handling_fee_bracket fkaxjm5sigdsi86ueu4pebrnphv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_bracket
    ADD CONSTRAINT fkaxjm5sigdsi86ueu4pebrnphv FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: cash_balance fkbhofh25twlb9k04sc4bv8gq0l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance
    ADD CONSTRAINT fkbhofh25twlb9k04sc4bv8gq0l FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_workgroup_branch fkbk0fawh4jpvxjx8iseyt25mec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_workgroup_branch
    ADD CONSTRAINT fkbk0fawh4jpvxjx8iseyt25mec FOREIGN KEY (workgroup_id) REFERENCES public.rate_workgroup(id);


--
-- Name: branch fkc121s316jwayhyhberonjbt4h; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT fkc121s316jwayhyhberonjbt4h FOREIGN KEY (branch_status_did) REFERENCES public.dictionary(id);


--
-- Name: branch fkc1oossj143dlws8xw0aqbkt1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch
    ADD CONSTRAINT fkc1oossj143dlws8xw0aqbkt1a FOREIGN KEY (country_did) REFERENCES public.dictionary(id);


--
-- Name: denomination fkc7toet3vkhgxt05gch58mcs8o; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination
    ADD CONSTRAINT fkc7toet3vkhgxt05gch58mcs8o FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: customer fkcc6lvs1hfb70cc5rjbyq0m8is; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT fkcc6lvs1hfb70cc5rjbyq0m8is FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: branch_group_branches fkcfh626bdyey86bdb529ssn8j; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.branch_group_branches
    ADD CONSTRAINT fkcfh626bdyey86bdb529ssn8j FOREIGN KEY (branch_group_id) REFERENCES public.branch_group(id);


--
-- Name: inventory_movement fkcmsfp7a7g32igqd1qvg4h00ay; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fkcmsfp7a7g32igqd1qvg4h00ay FOREIGN KEY (to_branch_id) REFERENCES public.branch(id);


--
-- Name: daily_balance fkcvva0wlk4j7dlm8hfslvt0jlw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_balance
    ADD CONSTRAINT fkcvva0wlk4j7dlm8hfslvt0jlw FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: archived_transactions fkdkj2way11eha5bfx4684xnx07; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.archived_transactions
    ADD CONSTRAINT fkdkj2way11eha5bfx4684xnx07 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: shipment_request_item fkdl83eskxp2mpft9h46bxintmf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shipment_request_item
    ADD CONSTRAINT fkdl83eskxp2mpft9h46bxintmf FOREIGN KEY (shipment_request_id) REFERENCES public.shipment_request(id);


--
-- Name: worker_role_permission fkdlo1rxmd31ch1f7hctyw4xcdr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_permission
    ADD CONSTRAINT fkdlo1rxmd31ch1f7hctyw4xcdr FOREIGN KEY (role_def_id) REFERENCES public.worker_role_def(id);


--
-- Name: camera_access_log fkdn6bfchp9ljg0l49m2cv9w7xs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.camera_access_log
    ADD CONSTRAINT fkdn6bfchp9ljg0l49m2cv9w7xs FOREIGN KEY (recording_id) REFERENCES public.camera_recording(id);


--
-- Name: storno_approval fkegwf0hi4d3f54kxgr9sbfee9w; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT fkegwf0hi4d3f54kxgr9sbfee9w FOREIGN KEY (approved_by_worker_id) REFERENCES public.worker(id);


--
-- Name: wu_balances fkex1499e98q5irw30wwero27bv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_balances
    ADD CONSTRAINT fkex1499e98q5irw30wwero27bv FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: led_display_config fkf5u3pjc7811hxkiako4bv0v97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.led_display_config
    ADD CONSTRAINT fkf5u3pjc7811hxkiako4bv0v97 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: role_permission fkf8yllw1ecvwqy3ehyxawqa1qp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permission
    ADD CONSTRAINT fkf8yllw1ecvwqy3ehyxawqa1qp FOREIGN KEY (permission_id) REFERENCES public.permission(id);


--
-- Name: daily_report fkfdarypom6pspfnc572ss8yygl; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_report
    ADD CONSTRAINT fkfdarypom6pspfnc572ss8yygl FOREIGN KEY (submitted_by_id) REFERENCES public.worker(id);


--
-- Name: collected_transaction fkfolu6klc955pui5yekie2n7ya; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collected_transaction
    ADD CONSTRAINT fkfolu6klc955pui5yekie2n7ya FOREIGN KEY (data_collection_id) REFERENCES public.data_collection(id);


--
-- Name: denomination fkfw9jhie54hhtbhuu34nplsq7w; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination
    ADD CONSTRAINT fkfw9jhie54hhtbhuu34nplsq7w FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: nav_closing_line fkfy4hfw6dlabi3pjfvvit40tkg; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_closing_line
    ADD CONSTRAINT fkfy4hfw6dlabi3pjfvvit40tkg FOREIGN KEY (nav_closing_id) REFERENCES public.nav_closing(id);


--
-- Name: transaction_line fkg1rcgpj1p3hcasn6ekoknvcoh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_line
    ADD CONSTRAINT fkg1rcgpj1p3hcasn6ekoknvcoh FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: transaction fkg94fj3emfpi6vw3xxij57dyuw; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT fkg94fj3emfpi6vw3xxij57dyuw FOREIGN KEY (original_transaction_id) REFERENCES public.transaction(id);


--
-- Name: daily_session fkgabb2kmaj5ah1tlft08hhyl50; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session
    ADD CONSTRAINT fkgabb2kmaj5ah1tlft08hhyl50 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: transfer fkghkpo8tvfb8pagu8x441j4o9x; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT fkghkpo8tvfb8pagu8x441j4o9x FOREIGN KEY (to_branch_id) REFERENCES public.branch(id);


--
-- Name: worker_role_assignment fkglmywousswlf58p1nlct2pcyp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_assignment
    ADD CONSTRAINT fkglmywousswlf58p1nlct2pcyp FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: email_account fkglo9kudrsanfwfg4ykt7cpd53; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT fkglo9kudrsanfwfg4ykt7cpd53 FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: transfer fkgsxo3d1s9gomlaas8pmpsr53m; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT fkgsxo3d1s9gomlaas8pmpsr53m FOREIGN KEY (from_worker_id) REFERENCES public.worker(id);


--
-- Name: profit_log fkgu22g65dmvfwf1mcdq9eb2yj9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profit_log
    ADD CONSTRAINT fkgu22g65dmvfwf1mcdq9eb2yj9 FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: exchange_rate fkh3b9j7ggn2lpd095tio6w58pp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate
    ADD CONSTRAINT fkh3b9j7ggn2lpd095tio6w58pp FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: rate_category fkh6h7hq94pi3hmlhk8yxw5pwde; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_category
    ADD CONSTRAINT fkh6h7hq94pi3hmlhk8yxw5pwde FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: worker_break fkhepwdcdkny0lwd9wfsjoc04in; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_break
    ADD CONSTRAINT fkhepwdcdkny0lwd9wfsjoc04in FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: transfer_document fkhfjvs5h7liiuhy17ujs3xrlb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document
    ADD CONSTRAINT fkhfjvs5h7liiuhy17ujs3xrlb FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: storno_approval fkhkqs3baljryiedqie3pe22omi; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT fkhkqs3baljryiedqie3pe22omi FOREIGN KEY (transaction_id) REFERENCES public.transaction(id);


--
-- Name: stamp_assignment fkhktm1gceqpa7m1hbeqgqba0yv; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stamp_assignment
    ADD CONSTRAINT fkhktm1gceqpa7m1hbeqgqba0yv FOREIGN KEY (stamp_batch_id) REFERENCES public.stamp_batch(id);


--
-- Name: sync_log fkhob8tp24kg7q98dqhoabcluow; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_log
    ADD CONSTRAINT fkhob8tp24kg7q98dqhoabcluow FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: vault_territory fkhx03h1j35cnn60f26ww7csfab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_territory
    ADD CONSTRAINT fkhx03h1j35cnn60f26ww7csfab FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: reservation fki65ouc7378d6wmp3p7b4e7lqr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT fki65ouc7378d6wmp3p7b4e7lqr FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: packaging_record fkilpommifplj9ocnk9naoksusk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.packaging_record
    ADD CONSTRAINT fkilpommifplj9ocnk9naoksusk FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: decade_report fkipy26y7xy6nqjued0a2o39rgb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.decade_report
    ADD CONSTRAINT fkipy26y7xy6nqjued0a2o39rgb FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: worker_role_permission fkira4lck9cbhyggc1a2y2bcp1l; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_role_permission
    ADD CONSTRAINT fkira4lck9cbhyggc1a2y2bcp1l FOREIGN KEY (permission_id) REFERENCES public.permission(id);


--
-- Name: led_display fkiutpiq5asfr637ddn2q2xq3y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.led_display
    ADD CONSTRAINT fkiutpiq5asfr637ddn2q2xq3y FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: police_request fkjpbetm0xo2kdko49svbo1kf7u; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.police_request
    ADD CONSTRAINT fkjpbetm0xo2kdko49svbo1kf7u FOREIGN KEY (created_by) REFERENCES public.worker(id);


--
-- Name: daily_session fkk0lxb8ib3q7saelevqsp9tnmm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_session
    ADD CONSTRAINT fkk0lxb8ib3q7saelevqsp9tnmm FOREIGN KEY (closed_by_worker_id) REFERENCES public.worker(id);


--
-- Name: worker_attendance fkkee0f907jq72xnbsn12863qr4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_attendance
    ADD CONSTRAINT fkkee0f907jq72xnbsn12863qr4 FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: storno_approval fkl4vorqlvr601e28jg2srk53uo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.storno_approval
    ADD CONSTRAINT fkl4vorqlvr601e28jg2srk53uo FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: rate_approval fkl68l5s3gfr4srutb8l5ihncbt; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_approval
    ADD CONSTRAINT fkl68l5s3gfr4srutb8l5ihncbt FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: transaction fklcx7g8g7x4fyns9k6vesu3n9n; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT fklcx7g8g7x4fyns9k6vesu3n9n FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: reservation fklioab2ehkn3s2aaxm74912x1i; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT fklioab2ehkn3s2aaxm74912x1i FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: reservation fklmijd0ej4b4x22lddv313yn0m; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT fklmijd0ej4b4x22lddv313yn0m FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: rate_approval fkmmfpmwtl2cggqgau3yaco3g6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_approval
    ADD CONSTRAINT fkmmfpmwtl2cggqgau3yaco3g6 FOREIGN KEY (approved_by) REFERENCES public.worker(id);


--
-- Name: collected_inventory fkmvscoitehu1lv9ywn50a8yxix; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collected_inventory
    ADD CONSTRAINT fkmvscoitehu1lv9ywn50a8yxix FOREIGN KEY (data_collection_id) REFERENCES public.data_collection(id);


--
-- Name: transfer_document fkn6sbst0prwbqu8caxajirvfx8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document
    ADD CONSTRAINT fkn6sbst0prwbqu8caxajirvfx8 FOREIGN KEY (courier_id) REFERENCES public.worker(id);


--
-- Name: wu_transactions fkndx0a0f5wm06vp6sxhmxtm2by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT fkndx0a0f5wm06vp6sxhmxtm2by FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: rate_approval fko0ne218phu1nli8hwc5k81as9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_approval
    ADD CONSTRAINT fko0ne218phu1nli8hwc5k81as9 FOREIGN KEY (requested_by) REFERENCES public.worker(id);


--
-- Name: monthly_closing_summary fko6t0vsfacc8xbrj1jawxgigjc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing_summary
    ADD CONSTRAINT fko6t0vsfacc8xbrj1jawxgigjc FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: inventory_movement fkoanvi3lmgrfkudlxstrou88dn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fkoanvi3lmgrfkudlxstrou88dn FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: circular fkoo3ank7a44phely3gmjul2bdl; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.circular
    ADD CONSTRAINT fkoo3ank7a44phely3gmjul2bdl FOREIGN KEY (created_by_id) REFERENCES public.worker(id);


--
-- Name: monthly_closing_summary fkorwnahq70jde5fkrp5902iind; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_closing_summary
    ADD CONSTRAINT fkorwnahq70jde5fkrp5902iind FOREIGN KEY (closed_by_worker_id) REFERENCES public.worker(id);


--
-- Name: inventory_summary fkp084axkmqb5gl81nwik9o411q; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_summary
    ADD CONSTRAINT fkp084axkmqb5gl81nwik9o411q FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: transaction_line fkpcwy5qy4l2qo2a67sdugbcxfr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_line
    ADD CONSTRAINT fkpcwy5qy4l2qo2a67sdugbcxfr FOREIGN KEY (transaction_id) REFERENCES public.transaction(id);


--
-- Name: mnb_report fkpe26hvodja36ocww2mk6ink5v; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mnb_report
    ADD CONSTRAINT fkpe26hvodja36ocww2mk6ink5v FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: data_collection fkphl8n6hhjdqckccn0tin9go1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_collection
    ADD CONSTRAINT fkphl8n6hhjdqckccn0tin9go1a FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: wu_transactions fkpkfm0x3thig33xu1j3o9xj1ra; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT fkpkfm0x3thig33xu1j3o9xj1ra FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- Name: exchange_rate fkpqmcfp4oyam6p9jcrodk1ha1q; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exchange_rate
    ADD CONSTRAINT fkpqmcfp4oyam6p9jcrodk1ha1q FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: denomination fkps324y4axh0oqfyej8wgg6li4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.denomination
    ADD CONSTRAINT fkps324y4axh0oqfyej8wgg6li4 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: employee_bank_account fkpyvhoiaovnuto1b6mqxtddxbj; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_bank_account
    ADD CONSTRAINT fkpyvhoiaovnuto1b6mqxtddxbj FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: employee_address fkq100ul0qo7nuxdcbn7adypnyo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_address
    ADD CONSTRAINT fkq100ul0qo7nuxdcbn7adypnyo FOREIGN KEY (employee_id) REFERENCES public.employee(id);


--
-- Name: ftp_sync_log fkqn6exv51j6bd5u05p5alcsdda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ftp_sync_log
    ADD CONSTRAINT fkqn6exv51j6bd5u05p5alcsdda FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: worker_competition_entry fkqq2c0v6lhqcn72nb4bnugwbva; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_competition_entry
    ADD CONSTRAINT fkqq2c0v6lhqcn72nb4bnugwbva FOREIGN KEY (competition_id) REFERENCES public.worker_competition(id);


--
-- Name: cash_balance fkqtwri2qn6bx4ewv0ncae6vlgn; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cash_balance
    ADD CONSTRAINT fkqtwri2qn6bx4ewv0ncae6vlgn FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: inventory_movement fkrfm0h87y2vhvj6yddnjrkm86y; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_movement
    ADD CONSTRAINT fkrfm0h87y2vhvj6yddnjrkm86y FOREIGN KEY (initiated_by_id) REFERENCES public.worker(id);


--
-- Name: nav_closing fkrvwbn463wb0b9uh316ce6kc2e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nav_closing
    ADD CONSTRAINT fkrvwbn463wb0b9uh316ce6kc2e FOREIGN KEY (closed_by) REFERENCES public.worker(id);


--
-- Name: transfer_document fkrxp08x7ydql12r44qkto7d1nh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer_document
    ADD CONSTRAINT fkrxp08x7ydql12r44qkto7d1nh FOREIGN KEY (sender_id) REFERENCES public.worker(id);


--
-- Name: closing_wizard fkrxxn6plxwad3a55e5d80mevb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.closing_wizard
    ADD CONSTRAINT fkrxxn6plxwad3a55e5d80mevb9 FOREIGN KEY (completed_by_worker_id) REFERENCES public.worker(id);


--
-- Name: worker fksrbh75havvuhwy110qdth7dhy; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker
    ADD CONSTRAINT fksrbh75havvuhwy110qdth7dhy FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: transfer fkstsm1iq0rvwv0ibw1ubg3o8qs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transfer
    ADD CONSTRAINT fkstsm1iq0rvwv0ibw1ubg3o8qs FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: worker_session fkt3xj15g0csrpc8xexk11po2nk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.worker_session
    ADD CONSTRAINT fkt3xj15g0csrpc8xexk11po2nk FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: email_account fkt4us76p2nfv1ylsf1inean6w1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT fkt4us76p2nfv1ylsf1inean6w1 FOREIGN KEY (vault_territory_id) REFERENCES public.vault_territory(id);


--
-- Name: data_import_jobs fktrk7hptqxjkviyw416ouh4028; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_import_jobs
    ADD CONSTRAINT fktrk7hptqxjkviyw416ouh4028 FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: email_account fkukcf8b5tny89ynpecoabw6m; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_account
    ADD CONSTRAINT fkukcf8b5tny89ynpecoabw6m FOREIGN KEY (own_company_id) REFERENCES public.own_company(id);


--
-- Name: handling_fee_decade_report handling_fee_decade_report_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.handling_fee_decade_report
    ADD CONSTRAINT handling_fee_decade_report_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branch(id);


--
-- Name: material_receipt_line material_receipt_line_receipt_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt_line
    ADD CONSTRAINT material_receipt_line_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES public.material_receipt(id) ON DELETE CASCADE;


--
-- Name: material_receipt material_receipt_vault_territory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.material_receipt
    ADD CONSTRAINT material_receipt_vault_territory_id_fkey FOREIGN KEY (vault_territory_id) REFERENCES public.vault_territory(id);


--
-- Name: rate_template rate_template_currency_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rate_template
    ADD CONSTRAINT rate_template_currency_id_fkey FOREIGN KEY (currency_id) REFERENCES public.currency(id);


--
-- Name: seal_tracking seal_tracking_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_tracking
    ADD CONSTRAINT seal_tracking_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: seal_tracking seal_tracking_opened_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_tracking
    ADD CONSTRAINT seal_tracking_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES public.worker(id);


--
-- Name: seal_tracking seal_tracking_sealed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seal_tracking
    ADD CONSTRAINT seal_tracking_sealed_by_fkey FOREIGN KEY (sealed_by) REFERENCES public.worker(id);


--
-- Name: vault_bank_transaction vault_bank_transaction_vault_territory_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_bank_transaction
    ADD CONSTRAINT vault_bank_transaction_vault_territory_id_fkey FOREIGN KEY (vault_territory_id) REFERENCES public.vault_territory(id);


--
-- Name: vault_distribution_line vault_distribution_line_distribution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_distribution_line
    ADD CONSTRAINT vault_distribution_line_distribution_id_fkey FOREIGN KEY (distribution_id) REFERENCES public.vault_distribution(id) ON DELETE CASCADE;


--
-- Name: vault_transfer vault_transfer_source_vault_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_transfer
    ADD CONSTRAINT vault_transfer_source_vault_id_fkey FOREIGN KEY (source_vault_id) REFERENCES public.vault_territory(id);


--
-- Name: vault_transfer vault_transfer_target_vault_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vault_transfer
    ADD CONSTRAINT vault_transfer_target_vault_id_fkey FOREIGN KEY (target_vault_id) REFERENCES public.vault_territory(id);


--
-- Name: wu_balances wu_balances_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_balances
    ADD CONSTRAINT wu_balances_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: wu_customers wu_customers_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_customers
    ADD CONSTRAINT wu_customers_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: wu_customers wu_customers_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_customers
    ADD CONSTRAINT wu_customers_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customer(id);


--
-- Name: wu_transactions wu_transactions_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT wu_transactions_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company(id);


--
-- Name: wu_transactions wu_transactions_worker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wu_transactions
    ADD CONSTRAINT wu_transactions_worker_id_fkey FOREIGN KEY (worker_id) REFERENCES public.worker(id);


--
-- PostgreSQL database dump complete
--

\unrestrict xQ9lewUYKxH7tUdXZksjZkCybDJMbmrdZSKry4nWngcyq0IDmWazVkclUwkfx8D

