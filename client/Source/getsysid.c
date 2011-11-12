
#ifdef AQBANKING
#include "getsysid.h"

#include <AqBanking/gwenhywfar/text.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

int getSysId(AB_BANKING *ab,
			 const char *bankId,
			 const char *userId,
			 const char *customerId,
			 char **errmsg )
{
	AB_PROVIDER *pro;
	AB_USER_LIST2 *ul;
	AB_USER *u=0;
	int rv;
	
	pro = AB_Banking_GetProvider(ab, "aqhbci");
	assert(pro);
	
	ul=AB_Banking_FindUsers(ab, AH_PROVIDER_NAME, "de",
							bankId, userId, customerId);
	if (ul) 
    {
		if( AB_User_List2_GetSize(ul) != 1 ) 
		{
			asprintf( errmsg, "Ambiguous customer specification");
			return 3;
		}
		else 
		{
			AB_USER_LIST2_ITERATOR *uit;
			
			uit=AB_User_List2_First(ul);
			assert(uit);
			u=AB_User_List2Iterator_Data(uit);
			AB_User_List2Iterator_free(uit);
		}
		AB_User_List2_free(ul);
    }
	if (!u) 
    {
		asprintf( errmsg, "No matching customer");
		return 3;
    }
	else 
	{
		AB_IMEXPORTER_CONTEXT *ctx;
		
		ctx = AB_ImExporterContext_new();
		rv = AH_Provider_GetSysId(pro, u, ctx, 0, 0, 1);
		AB_ImExporterContext_free(ctx);
		if( rv ) 
		{
			asprintf( errmsg, "Error getting system id (%d)", rv);
			return 3;
		}
	}
	
	
	return 0;
}

#endif