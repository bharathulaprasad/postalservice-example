### We can also solve the sample problem in Readme.md by using a trigger.


/* Optionally Log the data if there is any problem to see everything is alright
        TODO: remove these in production. Only for development purposes.*/
/*   DROP TABLE BSH_TRIGGER_LOG;
    CREATE TABLE BSH_TRIGGER_LOG (
                log_timestamp TIMESTAMP,
                log_message   VARCHAR2(4000)
                );
*/
                
CREATE OR REPLACE TRIGGER CUST_UPDATE_OBJECT_NAME AFTER
    UPDATE ON PITEMVERSIONMASTER
    FOR EACH ROW
BEGIN
    IF :new.puser_data_1 IS NOT NULL THEN
        -- Update the corresponding row in pworkspaceobject
        UPDATE pworkspaceobject wo
        SET
            wo.pobject_name = :new.puser_data_1
        WHERE
            wo.puid = (
                SELECT
                    wo.puid 
                FROM
                         pworkspaceobject wo
                    JOIN pimanrelation rel ON wo.puid = rel.rprimary_objectu
                    JOIN pform         frm ON frm.puid = rel.rsecondary_objectu
                WHERE
                    frm.rdata_fileu = :new.puid
            );
-- Optionally change also lsd (last set date) need to investigate??
        UPDATE ppom_object po
        SET
            po.plsd = sysdate + 4
        WHERE
            po.puid = (
                SELECT
                    po.puid
                FROM
                         ppom_object po
                    JOIN pimanrelation rel ON po.puid = rel.rprimary_objectu
                    JOIN pform         frm ON frm.puid = rel.rsecondary_objectu
                WHERE
                    frm.rdata_fileu = :new.puid
            );
   
 
        /*
       
        --Only used for debugging by creating some log
        INSERT INTO BSH_TRIGGER_LOG (
            log_timestamp,
            log_message
        ) VALUES (
            systimestamp,
            'UPDATE pworkspaceobject wo
        SET
            wo.pobject_name ='''  || :new.pbsh_rm_im_s_23  ||
        ''' WHERE
            wo.puid = (
                SELECT
                    wo.puid' ||
                ' FROM
                         pworkspaceobject wo
                    JOIN pimanrelation rel ON wo.puid = rel.rprimary_objectu
                    JOIN pform         frm ON frm.puid = rel.rsecondary_objectu
                WHERE
                    frm.rdata_fileu = ' || :new.puid || '
             );'
        );*/
 
    END IF;
END;
