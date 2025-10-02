public class FSL_JsonParseObjectPermission {

    Map<String,List<Id>> ListMap = New Map<String,List<Id>>();
    List<Id> enableRead = New List<Id>();
    List<Id> disableRead = New List<Id>();
    List<Id> enableCreate = New List<Id>();
    List<Id> disableCreate = New List<Id>();
    List<Id> enableEdit = New List<Id>();
    List<Id> disableEdit = New List<Id>();
    List<Id> enableDelete = New List<Id>();
    List<Id> disableDelete = New List<Id>();
    List<Id> enableViewAll = New List<Id>();
    List<Id> disableViewAll = New List<Id>();
    List<Id> enableModifyAll = New List<Id>();
    List<Id> disableModifyAll = New List<Id>();

    public Map<String, List<Id>> parseObjectPermissionJson(String jsonFile) {
        String listName;
        String idValue;
        JSONParser parser = JSON.createParser(jsonFile);
        while (parser.nextToken() != null) {
            //System.debug(parser.getCurrentToken() + ' : ' + parser.getText());
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                listName = parser.getText();
                parser.nextToken();
                while (parser.getCurrentToken() != JSONToken.END_ARRAY) {
                        if (parser.getCurrentToken() == JSONToken.VALUE_STRING) {
                            idValue = parser.getText();
                            //System.debug('List: ' + listName);
                            //System.debug('ID: ' + idValue);
                            distributeIds(listName, idValue);
                            parser.nextToken();
                        } else {parser.nextToken();}
                }
            }          
        }
        ListMap.put('enableRead', enableRead);
        ListMap.put('disableRead', disableRead);
        ListMap.put('enableCreate', enableCreate);
        ListMap.put('disableCreate', disableCreate);
        ListMap.put('enableEdit', enableEdit);
        ListMap.put('disableEdit', disableEdit);
        ListMap.put('enableDelete', enableDelete);
        ListMap.put('disableDelete', disableDelete);
        ListMap.put('enableViewAll', enableViewAll);
        ListMap.put('disableViewAll', disableViewAll);
        ListMap.put('enableModifyAll', enableModifyAll);
        ListMap.put('disableModifyAll', disableModifyAll);

        return ListMap;
        }

    public void distributeIds(String listName,  Id idValue){
        switch on listName {
            when 'enableRead' {
                enableRead.add(idValue);
            }
            when 'disableRead' {
                disableRead.add(idValue);
            }
            when 'enableCreate' {
                enableCreate.add(idValue);
            }
            when 'disableCreate' {
                disableCreate.add(idValue);
            }
            when 'enableEdit' {
                enableEdit.add(idValue);
            }
            when 'disableEdit' {
                disableEdit.add(idValue);
            }
            when 'enableDelete' {
                enableDelete.add(idValue);
            }
            when 'disableDelete' {
                disableDelete.add(idValue);
            }
            when 'enableViewAll' {
                enableViewAll.add(idValue);
            }
            when 'disableViewAll' {
                disableViewAll.add(idValue);
            }
            when 'enableModifyAll' {
                enableModifyAll.add(idValue);
            }
            when 'disableModifyAll' {
                disableModifyAll.add(idValue);
            }
        }
    }

}