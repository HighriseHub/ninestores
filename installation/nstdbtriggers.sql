
select 'creating a trigger to generate invoice numbers'
delimiter //
create trigger before_insert_invoice before insert on DOD_INVOICE_HEADER for each row 
    begin 
       	     declare next_id mediumint;
	     select auto_increment from information_schema.tables where table_schema = 'hhubdb' and table_name = 'DOD_INVOICE_HEADER' into next_id;
    	     set NEW.INVNUM = concat ('NST',lpad(next_id,5,"0"), "-",year(now()));
    end;//
delimiter ;
