/*  Bronze Layer */
--> Creating the tables and loading the data into the tables.

-- creating tables for source data
drop table bronze.crm_cst_info;
create or replace table bronze.crm_cst_info(
    cst_id INT,
    cst_key VARCHAR(50),
    cst_first_name varchar(50),
    cst_lastname varchar(50),
    cst_material_status varchar(50),
    cst_gndr varchar(50),
    cst_create_date DATE
);
-- create DDL scripts for CSV files in CRM and ERP systems
drop table bronze.crm_prd_info;
create or replace table bronze.crm_prd_info(
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt TIMESTAMP_NTZ,
    prd_end_dt TIMESTAMP_NTZ
);

drop table bronze.crm_sales_info;
create or replace table bronze.crm_sales_info(
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

drop table bronze.erp_loc_a101;
create or replace table bronze.erp_loc_a101(
    cid varchar(50),
    cntry varchar(50)
);
drop table bronze.erp_cst_az12;
create or replace table bronze.erp_cst_az12(
    cid varchar(50),
    bdate DATE,
    gen  varchar(50)
);

drop table bronze.erp_px_cat_g1v2;
create or replace table bronze.erp_px_cat_g1v2(
    id varchar(50),
    cat varchar(50),
    subcat varchar(50),
    maintenance varchar(50)
);

/* load the data into the files manually using UI 

select * from bronze.crm_cst_info; --18.5K records
select * from bronze.crm_prd_info; --397 records
select * from bronze.crm_sales_info; --60.4K records

select * from bronze.erp_cst_az12;  --18.5K records
select * from bronze.erp_loc_a101;  --18.5K records
select * from bronze.erp_px_cat_g1v2; --37 records

*/

-- Creating a stage to store the files from the local machine to Snowflake

create or replace stage local_stage;
--drop stage bronze.local_stage;

Show stages; -- shows the list of stages and details

CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = CSV
  SKIP_HEADER = 1;
--drop file format csv_format;

/*
Log in to SnowSQL using the command prompt in your local system
using snowsql -a account-name -u user-name > enter
Type the password when it prompts
Select the DB and schema
and load the files from local to Snowflake using 'PUT' command
-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_crm/cust_info.csv @local_stage;
-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_crm/prd_info.csv @local_stage;
-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_crm/sales_details.csv @local_stage;

-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_erp/cust_az1.csv @local_stage;
-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_erp/loc_a101.csv @local_stage;
-- PUT file://C:/Users/eswar/OneDrive/Desktop/sql_dwh/datasets/source_erp//px_cat_g1v2.csv @local_stage;

*/

list @local_stage; -- list the files inside the internal stage

/* sample to follow for loading data into tables from snowflake stage
copy into bronze.crm_cst_info
from  @local_stage/cust_info.csv.gz
FILE_FORMAT = (FORMAT_NAME = csv_format);
*/

-- creating a procedure to load all tables from the stage 
select getdate();

CREATE OR REPLACE PROCEDURE bronze.etl_main()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    v_customers_loaded NUMBER;
    v_products_loaded NUMBER;
    v_sales_loaded NUMBER;
    v_erp_cst_loaded NUMBER;
    v_erp_loc_loaded NUMBER;
    v_erp_px_cat_loaded NUMBER;
BEGIN
        
    --Load customers
    truncate table bronze.crm_cst_info;
    copy into bronze.crm_cst_info
    from  @local_stage/cust_info.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_customers_loaded AS (select count(*) from bronze.crm_cst_info);
    
    -- Load products
    truncate table bronze.crm_cst_info;
    copy into bronze.crm_prd_info
    from  @local_stage/prd_info.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_products_loaded AS (select count(*) from bronze.crm_prd_info);
    

    -- Load CRM_sales
    truncate table bronze.crm_sales_info;
    copy into bronze.crm_sales_info
    from  @local_stage/sales_details.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_sales_loaded as (select count(*) from bronze.crm_sales_info);

    -- Load ERP_CST_AZ12
    truncate table bronze.erp_cst_az12;
    copy into bronze.erp_cst_az12
    from  @local_stage/cust_az12.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_erp_cst_loaded as (select count(*) FROM bronze.erp_cst_az12);

    -- Load ERP_LOC_A101
    truncate table bronze.erp_loc_a101;
    copy into bronze.erp_loc_a101
    from  @local_stage/loc_a101.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_erp_loc_loaded as (select count(*) FROM bronze.erp_loc_a101);

    -- Load ERP_PX_CAT_G1V2
    truncate table bronze.erp_px_cat_g1v2;
    copy into bronze.erp_px_cat_g1v2
    from  @local_stage/px_cat_g1v2.csv.gz
    FILE_FORMAT =(FORMAT_NAME = csv_format);
    --create table v_erp_px_cat_loaded as (select count(*) FROM bronze.erp_px_cat_g1v2);
    

    RETURN 'ETL Completed Successfully!';

END;
$$;

CALL etl_main();

select * from bronze.crm_cst_info; -- 18.5k records
select * from bronze.crm_prd_info; --397 records
select * from bronze.crm_sales_info; -- 60.4k records
select * from ERP_CST_AZ12; --18.5k records
select * from ERP_LOC_A101; --18.5k records
select * from ERP_PX_CAT_G1V2; --37 records
