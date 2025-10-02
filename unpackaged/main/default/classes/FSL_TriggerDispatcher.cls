public class FSL_TriggerDispatcher {

    public interface ITriggerHandler{
        Boolean isDisabled();
        String getClassName();

        void beforeInsert();
        void afterInsert();
        void beforeUpdate();
        void afterUpdate();
        void beforeDelete();
        void afterDelete();
        void afterUnDelete();
    }

    public abstract class TriggerHandlerBase implements FSL_TriggerDispatcher.ITriggerHandler { 
        public abstract Boolean isDisabled();
        public virtual String getClassName() { return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':')); }

        public virtual void beforeInsert() {}
        public virtual void afterInsert() {}
        public virtual void beforeUpdate() {}
        public virtual void afterUpdate() {}
        public virtual void beforeDelete() {}
        public virtual void afterDelete() {}
        public virtual void afterUnDelete() {}
    }
     
    public static void run(ITriggerHandler handler) {
         
        if (handler.IsDisabled()){
            return;
        }

        
        
        FSL_Instrumentation.Context context = FSL_Instrumentation.start(handler.getClassName(), Trigger.OperationType, FSL_Instrumentation.safeRecordCount(Trigger.new, Trigger.old));
        
        try {
            switch on Trigger.operationType {
                when BEFORE_INSERT {
                    handler.beforeInsert();
                }
                when AFTER_INSERT {
                    handler.afterInsert();
                }
                when BEFORE_UPDATE {
                    handler.beforeUpdate();
                }
                when AFTER_UPDATE {
                    handler.afterUpdate();
                }
                when BEFORE_DELETE {
                    handler.beforeDelete();
                }
                when AFTER_DELETE {
                    handler.afterDelete();
                }
                when AFTER_UNDELETE {
                    handler.afterUnDelete();
                }
                when else {
                    if(Test.isRunningTest()) {
                        handler.beforeInsert(); //Need for unit test
                    }
                }
            }
        } finally {

            FSL_Instrumentation.end(context);

        }
    }
}