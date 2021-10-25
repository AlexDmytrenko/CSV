/**
 * Created by Alexey Dmytrenko on 22.10.2021.
 */

public with sharing class QueueableImportRecordsWithRelationship implements Queueable {
    private Map<String, String> oldIdToNewRelatedObj = new Map<String, String>();
    private List<String> fileLines = new List<String>();
    public QueueableImportRecordsWithRelationship(Map<String, String> oldIdToNewRelatedObj, List<String> fileLines) {
        this.oldIdToNewRelatedObj = oldIdToNewRelatedObj;
        this.fileLines = fileLines;
    }
    public void execute(QueueableContext context) {
        System.debug('+++' + fileLines);
        SObjectType schemaType = Schema.getGlobalDescribe().get('Contact');
        SObject record = schemaType.newSObject();
        List<SObject>records = new List<SObject>();
        String[] inputData = new String[]{
        };
        List<String> fields = new List<String>();

        for (Integer i = 1; i < fileLines.size(); i++) {
            fields = fileLines[0].split(',');
            inputData = fileLines[i].split('","');
            for (integer c = 1; c < fields.size(); c++) {

                if (inputData[c].contains('$') && oldIdToNewRelatedObj.get(inputData[c].replace('$', '')) != null) {
                    record.put(fields[c], oldIdToNewRelatedObj.get(inputData[c].replace('$', '')));
                    continue;
                }
                record.put(fields[c], inputData[c].replace('"', ''));
            }
            records.add(record);
        }
        System.debug(records);
        insert records;
    }
}