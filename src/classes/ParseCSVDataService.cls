/**
 * Created by Alexey Dmytrenko on 22.10.2021.
 */

public with sharing class ParseCSVDataService {
    public static Map<String,SObject> getData(String objectType) {
        StaticResource staticResourcer = [SELECT Id, Body FROM StaticResource WHERE Name = :objectType LIMIT 1];
        String body = staticResourcer.Body.toString();
        List<String>fileLines = body.split('\n');
        SObjectType schemaType = Schema.getGlobalDescribe().get(objectType);
        SObject record = schemaType.newSObject();
        List<String> ids = new List<String>();
        Map<String,SObject> oldIdToObject =  new Map<String,SObject>();
        String[] inputData = new String[]{
        };
        List<String> fields = new List<String>();

        for (Integer i = 1; i < fileLines.size(); i++) {
            fields = fileLines[0].split(',');
            inputData = fileLines[i].split('","');
            for (Integer c = 1; c < fields.size(); c++) {
                if (inputData[c].contains('$')){
                    continue;
                }
                record.put(fields[c], inputData[c].replace('"', ''));
            }
            oldIdToObject.put(inputData[0].replace('"', ''),record);
        }
        return oldIdToObject;
    }
//    public static Map<SObject,String> getDataWithRelationship(String objectType) {
//        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :objectType LIMIT 1];
//        String body = sr.Body.toString();
//        List<String>fileLines = body.split('\n');
//        SObjectType schemaType = Schema.getGlobalDescribe().get(objectType);
//        SObject record = schemaType.newSObject();
//        List<String> inputData = new List<String>();
//        List<String> fields = new List<String>();
//        Map<SObject,String> oldRelationToObject = new Map<SObject,String>();
//        String relatedId;
//        for (Integer i = 1; i < fileLines.size(); i++) {
//            inputData = fileLines[i].split('","');
//            fields = fileLines[0].split(',');
//            for (Integer c = 1; c < fields.size(); c++) {
//                if (inputData[c].contains('$')) {
//                    relatedId = inputData[c].replace('$', '');
//                    continue;
//                }
//                record.put(fields[c], inputData[c].replace('"', ''));
//
//            }
//            oldRelationToObject.put(record,relatedId);
//        }
//        return oldRelationToObject;
//    }
    //Use  only that method and move cycle with list<sobject> to queueable?
    //Pass to queueable  some boolean value isRelated?
    public static List<String> getDataRelated( String objectType) {
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = :objectType LIMIT 1];
        String body = staticResource.Body.toString();
        List<String>fileLines = body.split('\n');
        return fileLines;
    }
}