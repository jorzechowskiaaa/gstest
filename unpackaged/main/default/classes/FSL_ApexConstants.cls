/**
 * @File Name          : FSL_ApexConstants.cls
 * @Description        : Container for constant literals
 * @Author             :
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   : 04/03/2020
 * @Modification Log   :
 * Ver       Date           Author                 Modification
 * 1.0    4/3/2020         Masood Mahmood         Initial Version
**/

public with sharing class FSL_ApexConstants {
    //API Logs
    public static final String API_LOG_FAILED_REQUEST = '';
    public static final String API_LOG_SUCCESS_REQUEST = '';
    public static final String API_LOG_FAILED_RESPONSE = '';
    public static final String API_LOG_SUCCESS_RESPONSE = '';

    //Member Validation

    //IVR
    public static final String IVR_FAILED_RESPONSE_NO_MEMBER_FOUND  = 'IVR_RESPONSE_Error::No member found with that ';
    public static final String IVR_FAILED_RESPONSE_TOO_MANY_MEMBERS = 'IVR_RESPONSE_Error::More than One member found with that ';
    public static final String IVR_SUCCESS_RESPONSE                 = 'IVR_RESPONSE_SUCCESS::One & Only one member found with ';

    public static final String ANI_FAILED_RESPONSE_NO_MEMBER_FOUND  = 'ANI_RESPONSE_Error::No member found with ';
    public static final String ANI_FAILED_RESPONSE_TOO_MANY_MEMBERS = 'ANI_RESPONSE_Error::More than One member found with ';
    public static final String ANI_SUCCESS_RESPONSE                 = 'ANI_RESPONSE_SUCCESS::One & Only one member found with ';

    //Glympse (Both Inbound & Outbound)

    //Others
}