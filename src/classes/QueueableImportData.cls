/**
 * Created by Alexey Dmytrenko on 26.10.2021.
 */

public with sharing class QueueableImportData implements Queueable {
    public class ImportException extends Exception {
    }
    private List<ImportDataService.DataloaderTable> dataloaderTables;
    private Map<String, String> newIdsByOldIds;
    public QueueableImportData(List<ImportDataService.DataloaderTable> dataloaderTables, Map<String, String> newIdsByOldIds) {
        this.dataloaderTables = dataloaderTables;
        this.newIdsByOldIds = newIdsByOldIds;
    }
    public void execute(QueueableContext context) {
        List<String> fieldNames = dataloaderTables[0].fieldNames;
        String objectName = dataloaderTables[0].objectName;
        String[] inputData = new String[]{
        };
        List<String> oldIds = new List<String>();
        SObjectType schemaType = Schema.getGlobalDescribe().get(objectName);
        SObject record = schemaType.newSObject();
        List<SObject> sObjects = new List<SObject>();
        for (Integer i = 0; i < dataloaderTables[0].recordPrototypes.size(); i++) {
            inputData = dataloaderTables[0].recordPrototypes[i].split('","');
            dataloaderTables[0].recordPrototypes.remove(i);
            for (Integer c = 1; c < fieldNames.size(); c++) {
                if (inputData[c].contains('$')) {
                    if (newIdsByOldIds.get(inputData[c].replace('$', '')) == null) {
                        throw new ImportException('Invalid data. Number: '+c + ' Id: ' + inputData[c] );
                    }
                    record.put(fieldNames[c], newIdsByOldIds.get(inputData[c].replace('$', '')));
                    continue;

                }
                record.put(fieldNames[c], inputData[c].replace('"', ''));
                if(c>=200) {
                    break;
                }

            }
            sObjects.add(record);
            oldIds.add(inputData[0].replace('"', ''));
        }
        List<Database.SaveResult> insertResults = Database.insert(sObjects, true);
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (!insertResults[i].isSuccess()) {
            } else {
                newIdsByOldIds.put(oldIds[i], sObjects[i].Id);
            }
        }
        if (dataloaderTables[0].recordPrototypes.isEmpty()) {
            dataloaderTables.remove(0);
        }
        if (!dataloaderTables.isEmpty()) {
            System.enqueueJob(new QueueableImportData(dataloaderTables, newIdsByOldIds));
        }
    }
}