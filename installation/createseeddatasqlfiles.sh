mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_ABAC_SUBJECT > DOD_ABAC_SUBJECT.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_AUTH_ATTR_LOOKUP > DOD_AUTH_ATTR_LOOKUP.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_AUTH_POLICY > DOD_AUTH_POLICY.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_AUTH_POLICY_ATTR > DOD_AUTH_POLICY_ATTR.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_BUS_OBJECT > DOD_BUS_OBJECT.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_BUS_TRANSACTION > DOD_BUS_TRANSACTION.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_ROLES > DOD_ROLES.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_USERS > DOD_USERS.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_USER_ROLES > DOD_USER_ROLES.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb  DOD_GST_HSN_CODES > DOD_GST_HSN_CODES.sql
mysqldump -u hhubuser -p --column-statistics=0 --no-tablespaces --set-gtid-purged=OFF --single-transaction hhubdb   > completedatabase.sql

