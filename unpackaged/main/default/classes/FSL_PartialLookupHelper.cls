public class FSL_PartialLookupHelper {
    
    public static FSL_PartialLookupWrapper returnDummyData(){
        FSL_PartialLookupWrapper wrapper = new FSL_PartialLookupWrapper();

        List<FSL_MemberDetailsWrapper> memberList = new List<FSL_MemberDetailsWrapper>();
        FSL_MemberDetailsWrapper member1 = new FSL_MemberDetailsWrapper();
        member1.emailAddress ='testuser@aaa.com';
        member1.statusIndicator ='AAA indicator';
        member1.name = 'User 1';
        member1.memberNumber = '6200040000351503';
        member1.address = '123 Main St';
        member1.phoneNumber = '(555) 123-4567';

        memberList.add(member1);

        FSL_MemberDetailsWrapper member2 = new FSL_MemberDetailsWrapper();
        member2.name = 'User 2';
        member2.memberNumber = '6200040000439100';
        member2.address = '123 Main St';
        member2.phoneNumber = '(555) 123-4567'; 
        
        memberList.add(member2);

        wrapper.members = memberList;
        
        return wrapper;
    }

}