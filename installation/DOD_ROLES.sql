INSERT INTO `DOD_ROLES` (name, description, created, created_by, active_flg, deleted_state, updated_by)  VALUES
('SUPERADMIN','SUPERADMIN ROLE IS THE SUPREME ROLE IN ROLE HIERARCHY',CURRENT_TIMESTAMP,-1,'Y','N',-1),
('OPERATOR','Operator is the helpdesk. He can be assigned maintenance tasks on behalf of customers, vendors.',CURRENT_TIMESTAMP,-1,'Y','N',-1),
('COMPADMIN','Company Administrator is the helpdesk for a particular company/tenant. He can do maintenance tasks on behalf of customers, vendors for a given company',CURRENT_TIMESTAMP,-1,'Y','N',-1);
