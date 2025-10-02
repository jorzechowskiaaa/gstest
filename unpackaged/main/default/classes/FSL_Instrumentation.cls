public class FSL_Instrumentation {


    //=====================================================================================

    public class Entry {

        private Entry(FSL_Instrumentation instrument, String typeName) {
            this.instrument = instrument;
            this.typeName = typeName;
            this.nestedLevel = 0;
        }

        public Datetime startTime { get; private set; }
        public Datetime endTime  { get; private set; }
        public Long duration  { get; private set; }
        public Integer recordCount  { get; private set; }
        public Integer nestedLevel { get; private set; }
        
        private FSL_Instrumentation instrument;
        private String typeName;
        private TriggerOperation trigOperation;

    }

    public class Context {
        List<Entry> entries = new List<Entry>();
    }

    //=====================================================================================

    private static Map<String, FSL_Instrumentation> instances = null;


    public static FSL_Instrumentation createInstance(String key) {
        if(instances == null)
            instances = new Map<String, FSL_Instrumentation>();
            
        FSL_Instrumentation instrumentation = instances.get(key);
        if(instrumentation == null) {
            instrumentation = new FSL_Instrumentation(key);
            instances.put(key, instrumentation);
        } 

        return instrumentation;
    }

    public static FSL_Instrumentation getInstance(String key) {
        return instances == null ? null : instances.get(key);
    }

    public static Context start(String typeName) {
        return start(typeName, null, 0);
    }

    public static Context start(String typeName, TriggerOperation trigOperation, Integer recordCount) {
        if(isDebugging && instances == null) {
            createInstance(typeName).startInstrumenting();
        }

        if(instances != null) {

            Datetime now = Datetime.now();
            Context ctx = new Context();

            for (String key : instances.keySet()) {
                FSL_Instrumentation instr = instances.get(key);

                if(instr.isStarted) {
                    Entry entry = new Entry(instr, typeName);
                    entry.startTime = now;
                    entry.trigOperation = trigOperation;
                    entry.recordCount = recordCount;
    
                    ctx.entries.add(entry);
    
                    instr.doStart(entry);
                }
            }
            return ctx;
        }
        return null;
    }

    public static void end(Context ctx) {
        if(instances != null && ctx != null) {
            Datetime now = Datetime.now();
            try {
                for (Entry entry : ctx.entries) {
                    if(entry.instrument.isStarted) {
                        entry.instrument.doEnd(entry, now);
                    }
                }
            } catch (Exception ex) {
                //Ignore if context is invalid
            }

        }
    }

    public static FSL_Instrumentation_Setting__mdt LoadSettings(String name) {
        return configService.getSettings(name);
    }

    public static Integer safeRecordCount(List<SObject> newList, List<SObject> oldList) {
        return newList != null ? newList.size() : (oldList != null ? oldList.size() : 0);
    }


    //=====================================================================================
    public String key {get; private set; }
    private Boolean isStarted = false;
    private Integer currentNestedLevel = 0;


    private FSL_Instrumentation(String key) {
        this.key = key;
        this.entries = new List<Entry>();

        startTime = DateTime.now();
        endTime = DateTime.now();
    }
    
    public void startInstrumenting() {
        isStarted = true;
        startTime = DateTime.now();
    }

    public void stopInstrumenting() {
        isStarted = false;
        endTime = DateTime.now();
    }

    public List<Entry> entries { get; private set; }

    public DateTime startTime  { get; private set; }
    public DateTime endTime  { get; private set; }

    public Long calculateTotalEntriesDuration() {

        Long total = 0;
        for (Entry entry : this.entries) {
            if(entry.nestedLevel == 0)
                total += entry.duration;
        }

        return total;
    }

    public String toStringDetail() {

        String str = '';

        for (Entry entry : this.entries) {
            str = str + '\n' + entry.typeName + ': ';
            if(entry.trigOperation != null) {
                str = str + '\n' + entry.trigOperation.name() + ' - Rec. Count: ' + entry.recordCount;
            }
            str = str + '\n' + entry.startTime.format('HH:mm:ss.SSS') + ' - ' + entry.endTime.format('HH:mm:ss.SSS') + ' = ' + (entry.endTime.getTime() - entry.startTime.getTime()) + '\n';
            str = str + 'Nested Level: ' + entry.nestedLevel + '\n';
        }

        return str;
    }

    public String toStringSummary() {
        Map<String, Long> mapCombined = new Map<String, Long>();

        for (Entry entry : this.entries) {
            String key = entry.typeName;

            Long duration = mapCombined.get(key);
            if(duration == null) {
                duration = 0;
            }
            mapCombined.put(key, (duration + entry.duration));
        }

        List<String> keys = new List<String>(mapCombined.keySet());
        keys.sort();

        String str = '';
        for (String key : keys) {
            str = str + '\n' + key + ': ' + mapCombined.get(key);
        }
        return str;
    }

    public String toStringTriggersInfo(Datetime startTime, Datetime endTime, Boolean includeDetail) {

        Long totalDuration = endTime.getTime() - startTime.getTime();
        Long unmanagedDuration = calculateTotalEntriesDuration();

        LineBuffer lnBuff = new LineBuffer();

        lnBuff.addLine('\n--- Execution Summary ---\n');
        lnBuff.addLine('Total Duration: ');
        lnBuff.addline(startTime.format('HH:mm:ss.SSS') + ' - ' + endTime.format('HH:mm:ss.SSS') + ' = ' + totalDuration);
        lnBuff.addLine('Total Unmanaged Triggers Duration: ' + unmanagedDuration);


        lnBuff.addLine('\n--- Nested Triggers Summary ---');
        lnBuff.addLine(toStringSummary());

        if(includeDetail) {
            lnBuff.addLine('\n--- Nested Triggers Details ---');
            lnBuff.addLine(toStringDetail());
            lnBuff.addLine();
        }

        return lnBuff.toString();
    }

    public void logResult() {
        logResult('');
    }

    public void logResult(String operation) {
          
        FSL_Instrumentation_Setting__mdt instrSettings = LoadSettings(key);

        if(instrSettings.Enabled__c) {

            FSL_ApplicationLogCreator.CalloutLoggerData data = new FSL_ApplicationLogCreator.CalloutLoggerData();
            data.apiName = createApiName(key);
            data.operation = operation;
            data.isError = false;
            data.calloutRequest = '';
    
            data.calloutResponse = toStringTriggersInfo(startTime, endTime, instrSettings.Detail_Level__c == 'Verbose');
            FSL_ApplicationLogCreator.calloutLogger(data);

        }
    }

    //So we can search for all instrumentation logging using log filter: 'API Name' starts with 'Instrument'
    public static String createApiName(String key) {
        return 'Instrumentation: ' + key;
    }
    
    //================================================

    private void doStart(Entry entry) {     
        entry.nestedLevel = currentNestedLevel++;
        entries.add(entry);

        log(entry, 'START', currentNestedLevel);
    }

    private void doEnd(Entry entry, Datetime now) {
        entry.endTime = now;
        entry.duration = now.getTime() - entry.startTime.getTime();

        log(entry, 'STOP', currentNestedLevel);

        currentNestedLevel--;
    }

    private static void log(Entry entry, String state, Integer nestedLevel) {
        if(isDebugging) {
            System.debug('<<< Instrumentation Name: ' + entry.instrument.key + ' >>> ' + state + ' ' + entry.typeName + ' ' + entry.trigOperation + ' Nested Level ' + nestedLevel);

        }
    }

    //================================================

    @TestVisible
    private static IConfigService configService = new ConfigService();

    @TestVisible
    private static Boolean isDebugging = false;

    public interface IConfigService {
        FSL_Instrumentation_Setting__mdt getSettings(String name);
    }

    private class ConfigService implements IConfigService {
        public FSL_Instrumentation_Setting__mdt getSettings(String name) {
            FSL_Instrumentation_Setting__mdt[]  settings = [SELECT Label, Enabled__c, Detail_Level__c FROM FSL_Instrumentation_Setting__mdt WHERE Label =: name];
        
            FSL_Instrumentation_Setting__mdt setting;
            if(settings.size() > 0) {
                setting = settings[0];
            } else {
                setting = new FSL_Instrumentation_Setting__mdt();
                setting.Enabled__c = false;
            }
    
            return setting;
        }
    }

    //================================================
    public class LineBuffer { //here for now
        private List<String> lines = new List<String>();

        public void addLine() {
            lines.add('');
        }
        
        public void addLine(String line) {
            lines.add(line);
        }

        public override String toString() {
            String str = '';
            for (String line : lines) {
                str += line + '\n';
            }
            return str;
        }
    }
}