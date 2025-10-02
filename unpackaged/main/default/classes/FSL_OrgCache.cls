public class FSL_OrgCache {

    public static Id sysAdminProfileId() {
        Profile p = (Profile)Cache.Org.get(ProfileCache.class, 'System Administrator');
        return p == null ? null : p.Id;
    }


    class ProfileCache implements Cache.CacheBuilder {
        public Object doLoad(String profileName) {
            List<Profile> results =[SELECT Id FROM Profile WHERE Name =:profileName LIMIT 1];
            return results.isEmpty() ? null : results[0];
        }
    }
}