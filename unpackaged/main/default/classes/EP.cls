/**
 * A utility class for app-wide constants, exceptions, and utility functions
 *
 * @author Steve Cox
 */
public class EP {  
    /** Assert a precondition; throws on failure when debugging */
  public static void preCondition(Boolean condition, Object message) {
    assert(condition, 'preCondition failed: ' + message);
  }
  /** Assert a postcondition; throws on failure when debugging */
  public static void postCondition(Boolean condition, Object message) {
    assert(condition, 'postCondition failed: ' + message);
  }
     /** base class for all exceptions */
  public abstract class EP_Exception extends Exception {
  }
 
      /** a failed assertion */
  public class AssertionException extends EP_Exception {
  }

  /** Assert a condition; throws on failure when debugging*/
  public static void assert(Boolean condition, Object message) {
    if (!condition) {
      throw new AssertionException(String.valueOf(message));
    }
  }

  //--------------------------------------------------------------------------
  // Record Types
  private static Map<String, Id> rtCache;
  
  /**
   * Where you use record types on several objects, a convenient way to obtain the
   * record type ID in Apex is needed. And as the record type ID requires a SOQL
   * query to obtain the org-specific value, governor limits and efficiency come in
   * to play too.
   *
   * <p>The pattern illustrated here allows the ID to be obtained using this simple
   * and flexible call: <code>Id rt = EP.getRecordTypeId(Account.SObjectType, 'Household');</code>
   *
   * <p>The benefits of this approach are:
   * <ol>
   * <li>Only one SOQL query done (per server request) no matter how many record
   *   type IDs are referenced or where they are referenced e.g. inside a loop.</li>
   * <li>Avoids problems of typos in strings by using the compile-time checked
   *   SObjectType field.</li>
   * </ol>
   *
   * <p>(from <a href="http://force201.wordpress.com/2011/07/22/accessing-record-type-ids-in-apex-code/">
   * Force 201's article</a>)
   *
   * @param obType the object type
   * @param devName the developer name of the record type
   * @return the record type Id, or null if not found
   */
  public static Id getRecordTypeId(SObjectType obType, String devName) {
    EP.preCondition(null != obType, 'EP.getRecordTypeId() - invalid obType');
    EP.preCondition(null != devName, 'EP.getRecordTypeId() - invalid devName');
    
    if (null == rtCache) {
      rtCache = new Map<String, Id>();
      for (RecordType t : [SELECT SObjectType, DeveloperName FROM RecordType WHERE IsActive = true]) {
        rtCache.put(t.SObjectType + t.DeveloperName, t.Id);
      }
    }
    
    final Id result = rtCache.get(obType + devName);
    EP.postCondition(null != result, 'EP.getRecordTypeId() - type not found');
    return result;
  }

  @testVisible private EP() {} // prevent construction
}