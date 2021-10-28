/**
 * Created by Alexey Dmytrenko on 26.10.2021.
 */

public with sharing class ImportDataService {
    public static void importData(String staticResourceName, List<String> fileNamesToUpload) {
        List<DataloaderTable> dataloaderTables = new List<DataloaderTable>();
        StaticResource staticResource = [SELECT Id,SystemModstamp FROM StaticResource WHERE Name = :staticResourceName];
        for (String fileName : fileNamesToUpload) {
            String srPath = '/resource/' + staticResource.SystemModstamp.getTime() + '/Files/' + fileName ;
            PageReference pg = new PageReference(srPath);
            String body = pg.getContent().toString();
            List<String>fileLines = body.split('\n');
            List<String>fields = fileLines[0].split(',');
            fileLines.remove(0);
            DataloaderTable dataloaderTable = new DataloaderTable();
            dataloaderTable.fieldNames = fields;
            dataloaderTable.objectName = fileName;
            dataloaderTable.recordPrototypes = fileLines;
            dataloaderTables.add(dataloaderTable);
        }
        if (!dataloaderTables.isEmpty()) {
            System.enqueueJob(new QueueableImportData(dataloaderTables, new Map<String, String>()));
        }
    }
    public with sharing class DataloaderTable {
        public List<String> fieldNames;
        public List<String> recordPrototypes;
        public String objectName;

    }

}