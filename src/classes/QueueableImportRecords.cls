/**
 * Created by Alexey Dmytrenko on 22.10.2021.
 */

public with sharing class QueueableImportRecords implements Queueable {
    Map<String, SObject> oldIdToObject = new Map<String, SObject>();
    List<String>relatedObjFileLines = new List<String>();
    public QueueableImportRecords(Map<String, SObject> oldIdToObject, List<String>relatedObjFileLines) {
        this.oldIdToObject = oldIdToObject;
        this.relatedObjFileLines = relatedObjFileLines;
    }

    public void execute(QueueableContext context) {
        List<SObject> sObjects = oldIdToObject.values();

        List<String> oldIds = new List<String>();
        for (String key : oldIdToObject.keySet()) {
            oldIds.add(key);
        }

        Map<String, String> oldIdToNew = new Map<String, String>();

        List<Database.Saveresult> insertResults = Database.insert(sObjects, false);
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (!insertResults[i].isSuccess()) {
                oldIdToNew.put(oldIds[i], null);
            } else {
                oldIdToNew.put(oldIds[i], sObjects[i].Id);
            }
        }
        QueueableImportRecordsWithRelationship queueableImportRecordsWithRelationship =
            new queueableImportRecordsWithRelationship(oldIdToNew, relatedObjFileLines);
        System.enqueueJob(queueableImportRecordsWithRelationship);
    }

}