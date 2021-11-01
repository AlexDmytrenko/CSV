/**
 * Created by Alexey Dmytrenko on 26.10.2021.
 */

public with sharing class ImportDataService {

    public static void importData(String staticResourceName, List<String> fileNamesToUpload) {
        List<DataloaderTable> dataloaderTables = new List<DataloaderTable>();
        StaticResource staticResource = [SELECT Id,SystemModstamp FROM StaticResource WHERE Name = :staticResourceName];
        for (String fileName : fileNamesToUpload) {
            List<String>fileLines = getFileLines(StaticResource, fileName);
            List<String>fields = fileLines.remove(0).split(',');
            DataloaderTable dataloaderTable = new DataloaderTable(fields, fileLines, fileName);
            dataloaderTables.add(dataloaderTable);
        }
        if (!dataloaderTables.isEmpty()) {
            System.enqueueJob(new QueueableImportData(dataloaderTables, new Map<String, String>()));
        }
    }

    public static List<String> getFileLines(StaticResource staticResource, String fileName) {
        String srPath = '/resource/' + staticResource.SystemModstamp.getTime() + '/Files/' + fileName ;
        PageReference pg = new PageReference(srPath);
        String body = pg.getContent().toString();
        List<String>fileLines = body.split('\n');
        System.debug(fileLines);
        return fileLines;
    }

    public class DataloaderTable {
        public List<String> fieldNames;
        public List<String> recordPrototypes;
        public String objectName;
        public DataloaderTable(List<String> fieldNames,
            List<String> recordPrototypes,
            String objectName
        ) {
            this.fieldNames = fieldNames;
            this.recordPrototypes = recordPrototypes;
            this.objectName = objectName;

        }
    }

}