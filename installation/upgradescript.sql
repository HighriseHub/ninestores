select 'Modifying table DOD_ORDER adding a new column storepickupenabled' as ' ';   
ALTER TABLE DOD_ORDER  ADD COLUMN IF NOT EXISTS STOREPICKUPENABLED CHAR(1) DEFAULT NULL; 
