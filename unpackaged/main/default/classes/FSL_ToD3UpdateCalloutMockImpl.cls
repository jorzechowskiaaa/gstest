global class FSL_ToD3UpdateCalloutMockImpl implements HttpCalloutMock {
    protected Integer code;
    protected String status;
    protected String body;
    protected Map<String, String> responseHeaders;

    public FSL_ToD3UpdateCalloutMockImpl (Integer code, String status, String body, Map<String, String> responseHeaders) {
        this.code = code;
        this.status = status;
        this.body = body;
        this.responseHeaders = responseHeaders;
    }

    public HTTPResponse respond(HTTPRequest req) {
        //Create a fake response
        HttpResponse res = new HttpResponse();
        if(req.getEndpoint() != null && req.getEndpoint().contains('org_id=81511&foreign_id=') ) {
           res.setBody('{\"result\":\"ok\",\"body\":{\"tasks\":[{\"properties\":[{\"n\":\"appt_from\",\"v\":1556130900000},{\"n\":\"appt_to\",\"v\":1556174100000},{\"n\":\"invite_code\",\"v\":\"0H6Q-BMPM\"},{\"n\":\"phase\",\"v\":\"pre\"}]},{\"properties\":[{\"n\":\"appt_from\",\"v\":1556157480000},{\"n\":\"appt_to\",\"v\":1556159760000},{\"n\":\"invite_code\",\"v\":\"0XS6-YJBG\"},{\"n\":\"eta\",\"v\":{\"eta\":64140000,\"eta_ts\":1556145135584}},{\"n\":\"name\",\"v\":\"WB Technician\"},{\"n\":\"phase\",\"v\":\"live\"}]}]},\"meta\":{\"time\":1556274828893}}');
          //  res.setBody('{"example":"test"}');
            res.setStatusCode(this.code);
            res.setStatus(this.status);
        }else {
            for (String key : this.responseHeaders.keySet()) {
                res.setHeader(key, this.responseHeaders.get(key));
            }
            res.setBody(this.body);
            res.setStatusCode(this.code);
            res.setStatus(this.status);
        }
        return res;
    }
}