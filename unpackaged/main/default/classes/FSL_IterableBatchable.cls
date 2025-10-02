// This class enables implementing batchable logic using inner class via IBatchable interface avoiding polluting class files
public with sharing class FSL_IterableBatchable implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public interface IBatchable {
        Iterable<SObject> start(Database.BatchableContext context);
         void execute(Database.BatchableContext context, List<SObject> items);
         void finish(Database.BatchableContext context);
    }

    private IBatchable batchable;

    public FSL_IterableBatchable(IBatchable batchable) {
        this.batchable = batchable;
    }


    public Iterable<SObject> start(Database.BatchableContext context) {

        return batchable.start(context);
    }

    public void execute(Database.BatchableContext context, List<SObject> items) {
        batchable.execute(context, items);
    }

    public void finish(Database.BatchableContext context) {
        batchable.finish(context);
    }
}