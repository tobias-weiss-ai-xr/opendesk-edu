{{groovy}}
// SPDX-FileCopyrightText: 2025 XWiki SAS
// SPDX-License-Identifier: LGPL-2.1-only
import org.apache.commons.lang3.StringUtils;
import org.xwiki.refactoring.job.ReplaceUserRequest;

class DuplicateUserAccountsHelper {
  def services;
  DuplicateUserAccountsHelper (def services) {
    this.services = services;
  }
  def getDuplicates(){
    // Get all users accounts created by "LDAP User Import" application
    def ldapUserSubjectReferenceMap = [:];
    def xwql = 'select oidcUser.subject, doc.fullName from Document doc, doc.object(XWiki.LDAPProfileClass) as ldapUser, doc.object(XWiki.OIDC.UserClass) as oidcUser';
    def results = services.query.xwql(xwql).execute();
    for(def result : results){
      ldapUserSubjectReferenceMap.put(StringUtils.lowerCase(result[0]), result[1]);
    }
    // Get duplicated user pages created by OIDC authenticator
    xwql = 'select doc.fullName, oidcUser.subject from Document doc, doc.object(XWiki.OIDC.UserClass) as oidcUser where doc.fullName not in (:ldapUsers) and oidcUser.subject in (:subjects)';
    results = services.query.xwql(xwql).bindValue('ldapUsers', ldapUserSubjectReferenceMap.values()).bindValue('subjects', ldapUserSubjectReferenceMap.keySet()).execute();
    def duplicates = [];
    for(def result in results){
      def duplicate = result[0];
      def subject = result[1];
      duplicates.add(['account' : ldapUserSubjectReferenceMap.get(subject), 'duplicate' : duplicate]);
    }
    return duplicates;
  }

  def replaceDuplicateUserAccount(def account, def duplicateAccount){
    def oldUserReference = services.model.resolveDocument(duplicateAccount);
    def newUserReference = services.model.resolveDocument(account);
    ReplaceUserRequest request = services.refactoring.getRequestFactory().createReplaceUserRequest(oldUserReference, newUserReference);
    request.setReplaceDocumentAuthor(true);
    request.setReplaceDocumentContentAuthor(true);
    request.setReplaceDocumentCreator(true);
    return services.refactoring.replaceUser(request);
  }
}

def duplicateUserAccountsHelper = new DuplicateUserAccountsHelper(services);
xcontext.put('duplicateUserAccountsHelper', duplicateUserAccountsHelper);
if(request.disableDuplicateUserAccounts == 'true'){
  if(hasProgramming){
    System.out.println("> Start disabling duplicate user accounts script");
    def duplicates = duplicateUserAccountsHelper.getDuplicates();
    for(def item : duplicates){
      def logMessage;
      try {
        def job = duplicateUserAccountsHelper.replaceDuplicateUserAccount(item.account, item.duplicate);
        // wait for job completion
        job.join();
        if (job.getStatus().getError()) {
          logMessage = "Failed to replace duplicate user account [${item.duplicate}] by account [${item.account}] : ${job.getStatus().getError()}";
          println "* {{error}}${logMessage}{{/error}}";
        } else {
          // Disable duplicate user
          def user = xwiki.getUser(services.model.resolveDocument(item.duplicate));
          user.setDisabledStatus(true);
          logMessage = "Duplicate user account [${item.duplicate}] has been replaced by account [${item.account}] and disabled.";
          println "* ${logMessage}";
       }
       System.out.println("--- ${logMessage}");
      }
      catch(Exception e){
        logMessage = "Failed to replace and disable duplicate user account [${item.duplicate}]";
        println "* {{error}}${logMessage}{{/error}}";
        System.out.println("--- ${logMessage}");
        e.printStackTrace();
      }
    }
    System.out.println("< End of script");
  }
  else
  {
    println "{{error}}You are not allowed to execute this script. This script requires programming rights to be executed, please contact your administrator.{{/error}}";
  }
}
{{/groovy}}

{{velocity}}
#if("$!request.showDuplicateUserAccounts" == 'true')
  #set ($duplicateUserAccountsHelper = $xcontext.get('duplicateUserAccountsHelper'))
  #set($duplicates = $duplicateUserAccountsHelper.getDuplicates())
  #if($duplicates.size() > 0)
    == Duplicate user accounts ($duplicates.size()) ==

    (% style="max-height:500px;overflow:scroll;" %)
    (((
      |=Account|=Duplicate
      #foreach($item in $duplicates)
      |[[$item.account>>$item.account]]|[[$item.duplicate>>$item.duplicate|| target="_blank"]]
      #end
    )))

    [[Replace and disable duplicate user accounts>>$doc.fullName||queryString="disableDuplicateUserAccounts=true" class="button"]]
    //Note that the script logs are displayed on the UI but in case you got a connection timeout error please check the web application logs to follow the progress of the script.//
  #else
    {{info}}
      No duplicate user accounts found!
    {{/info}}
  #end
#elseif("$!request.disableDuplicateUserAccounts" != 'true')
 {{info}}
   The objective of this script is to check if there are any duplicate user accounts and to disable them safely.
 {{/info}}

 [[Show duplicate user accounts>>$doc.fullName||queryString="showDuplicateUserAccounts=true" class="button"]]
#end
{{/velocity}}