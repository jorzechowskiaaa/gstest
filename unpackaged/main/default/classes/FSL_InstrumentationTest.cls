@isTest
public class FSL_InstrumentationTest {

    static void func1() {
        FSL_Instrumentation.Context ctx = FSL_Instrumentation.start('func1');
        func2();
        delay(100);
        FSL_Instrumentation.end(ctx);
    
    }
    
    static void func2() {
        FSL_Instrumentation.Context ctx = FSL_Instrumentation.start('func2');
        delay(200);
        func3();
        FSL_Instrumentation.end(ctx);
    }
    
    
    static void func3() {
        List<SObject> newList = null;
        List<SObject> oldList = new List<SObject>();
        FSL_Instrumentation.Context ctx = FSL_Instrumentation.start('func3', TriggerOperation.BEFORE_INSERT, FSL_Instrumentation.safeRecordCount(newList, oldList));
        delay(300);
        FSL_Instrumentation.end(ctx);
    }
    
    static void delay(Integer milliSec) {
        Long start = Datetime.now().getTime();
        while(Datetime.now().getTime() - start < milliSec);
    }
    
    @isTest
    static void testInstrumentation() {
    
        FSL_Instrumentation inst = FSL_Instrumentation.createInstance('instance 1');
        inst.startInstrumenting();
        func1();
        inst.stopInstrumenting();

    
        System.debug('===== inst Summary =====');
        System.debug(inst.toStringSummary());
        System.debug('\n\n=====inst Detail=====');
        System.debug(inst.toStringDetail());
    
        FSL_Instrumentation inst2 = FSL_Instrumentation.createInstance('instance 2');
        inst2.startInstrumenting();
        func2();
        inst2.stopInstrumenting();
    
        System.debug('===== inst2 Summary =====');
        System.debug(inst2.toStringSummary());
        System.debug('\n\n=====inst2 Detail=====');
        System.debug(inst2.toStringDetail());
    
        System.assert(inst.entries[0].nestedLevel == 0);
        System.assert(inst.entries[1].nestedLevel == 1);
        System.assert(inst.entries[2].nestedLevel == 2);
        System.assert(inst.entries[0].duration > inst.entries[1].duration);
        System.assert(inst.entries[1].duration > inst.entries[2].duration);
    
        System.assert(inst2.entries[0].nestedLevel == 0);
        System.assert(inst2.entries[1].nestedLevel == 1);
        System.assert(inst2.entries[0].duration > inst2.entries[1].duration);
    
    }

    @IsTest
    static void testTriggerDispatchInstrumentationExceptionHandling(){
        
        Test.startTest();
    
        FSL_Instrumentation instru = FSL_Instrumentation.createInstance(FSL_InstrumentationTest.class.getName());
        instru.startInstrumenting();
        
        Boolean firstExeptionCaught = false;
        Boolean secondExeptionCaught = false;
        FSL_TriggerDispatcher.ITriggerHandler handler = new SampleTriggerHandler();
        try {
            FSL_TriggerDispatcher.run(handler);
        } catch (Exception ex1) {
            firstExeptionCaught = true;
            try {
                String strDetail = instru.toStringDetail();
            } catch (Exception ex2) {
                secondExeptionCaught = true;
            }
        }
        
        System.assert((FSL_InstrumentationTest.class.getName() + '.' + handler.getClassName()) == SampleTriggerHandler.class.getName());
        System.assert(firstExeptionCaught);
        System.assert(secondExeptionCaught == false);

        Test.stopTest();
        
    }

    class SampleTriggerHandler extends FSL_TriggerDispatcher.TriggerHandlerBase {
        
        public override Boolean isDisabled() {
            return false;
        }
    
        //========================================================================================================================
        //========================================================================================================================
        public override void beforeInsert() {
            throw new DmlException('Testing Exception');
        }
    
    
    }

    
}