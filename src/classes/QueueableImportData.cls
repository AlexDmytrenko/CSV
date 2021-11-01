/**
 * Created by Alexey Dmytrenko on 26.10.2021.
 */

public with sharing class QueueableImportData implements Queueable {
    static final Integer RECORDS_PER_CHUNK = 200;
    private List<ImportDataService.DataloaderTable> dataloaderTables;
    private Map<String, String> newRecordIdsByExternalIds;
    private List<String> fieldNames {
        get {
            return dataloaderTables[0].fieldNames;
        }
    }
    private String objectName {
        get {
            return dataloaderTables[0].objectName;
        }
    }
    private List<String> recordPrototypes {
        get {
            return dataloaderTables[0].recordPrototypes;
        }
    }
    public QueueableImportData(List<ImportDataService.DataloaderTable> dataloaderTables, Map<String, String> newIdsByOldIds) {
        this.dataloaderTables = dataloaderTables;
        this.newRecordIdsByExternalIds = newIdsByOldIds;
    }
    public void execute(QueueableContext context) {
        System.debug(dataloaderTables[0].recordPrototypes);
        List<String> oldIds = new List<String>();
        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        SObject record = objectType.newSObject();
        List<SObject> records = new List<SObject>();
        List<String> inputData;
        for (Integer i = 0; i < RECORDS_PER_CHUNK && recordPrototypes.size() > 0; i++) {
            inputData = getFieldData(recordPrototypes[i]);
            recordPrototypes.remove(i);

            for (Integer j = 0; j < fieldNames.size(); j++) {
                Object value = getAppropriateObject(objectType, fieldNames[j], inputData[j]);

                if (inputData[j].contains('$')) {
                    if (newRecordIdsByExternalIds.get(inputData[j].replace('$', '')) == null) {
                        throw new ImportException('Invalid data. Line: ' + i + 1 + ' Id: ' + inputData[j]);
                    }
                    value = newRecordIdsByExternalIds.get(inputData[j].replace('$', ''));
                }
                record.put(fieldNames[j], value);
            }
            records.add(record);
            oldIds.add(inputData[0]);
        }
        insert records;
        for (Integer i = 0; i < records.size(); i++) {
            newRecordIdsByExternalIds.put(oldIds[i], records[i].Id);
        }
        if (recordPrototypes.isEmpty()) {
            dataloaderTables.remove(0);
        }
        if (!dataloaderTables.isEmpty()) {
            System.enqueueJob(new QueueableImportData(dataloaderTables, newRecordIdsByExternalIds));
        }
    }

    public Object getAppropriateObject(SObjectType objectType, String fieldName, Object value) {
        DescribeFieldResult describeFieldResult = objectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
        if (describeFieldResult.isUpdateable()) {
            DisplayType type = describeFieldResult.type;
            if (type == DisplayType.BOOLEAN) {
                return Boolean.valueOf(value);
            } else if (type == DisplayType.DATE) {
                return Date.valueOf(value);
            } else if (type == DisplayType.DATETIME) {
                return Datetime.valueOf(value);

            } else if (type == DisplayType.INTEGER) {
                return Integer.valueOf(value);

            } else if (type == DisplayType.DOUBLE) {
                return Double.valueOf(value);
            } else {
                return value;
            }
        }
        return null;
    }

    public List<String> getFieldData(String record) {
        List<String> chars = record.split('');
        String fieldData = '';
        List<String> fieldDataList = new List<String>();
        Integer count = 0;
        for (Integer i = 0; i < chars.size(); i++) {
            if (chars[i] == '"') {
                count++;
            }
            fieldData = fieldData + chars[i];
            if ((chars[i] == ',' || i == chars.size() - 1) && Math.mod(count, 2) == 0) {
                fieldDataList.add(fieldData.removeEnd(',').removeEnd('"').removeStart('"'));
                fieldData = '';
            }
        }
        return fieldDataList;
    }

    public class ImportException extends Exception {
    }

}