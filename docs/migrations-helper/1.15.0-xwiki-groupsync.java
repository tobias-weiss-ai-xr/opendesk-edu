{{groovy}}
// SPDX-FileCopyrightText: 2026 XWiki SAS
// SPDX-License-Identifier: LGPL-2.1-only
import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;
import javax.inject.Provider;

import org.apache.commons.lang3.StringUtils;

import org.xwiki.contrib.ldap.LDAPDocumentHelper;
import org.xwiki.contrib.ldap.XWikiLDAPUtils;
import org.xwiki.contrib.ldap.XWikiLDAPConfig;
import org.xwiki.contrib.ldap.XWikiLDAPConnection;
import org.xwiki.contrib.ldap.XWikiLDAPSearchAttribute;
import com.xwiki.ldapuserimport.internal.XWikiLDAPUtilsHelper;
import com.novell.ldap.LDAPConnection;
import org.xwiki.component.util.DefaultParameterizedType;
import static org.xwiki.contrib.ldap.XWikiLDAPUtils.cleanXWikiUserPageName;

def associateGroups(String[] ldapGroupsArray, String xWikiGroupName, def ldapConfiguration) {
  if (ldapGroupsArray.length > 0) {
    def configSourceDocRef = services.model.resolveDocument('XWiki.XWikiPreferences')
    def configSourceDoc = xwiki.getDocument(configSourceDocRef)
    Set<String> ldapGroupsSetToAdd = new HashSet<String>(Arrays.asList(ldapGroupsArray))
    Map<String, Set<String>> groupMapping = ldapConfiguration.getGroupMappings()
    for (Entry<String, Set<String>> entry : groupMapping.entrySet()) {
      Set<String> modifiedSet =
      entry.getValue().stream().map((value) -> StringUtils.replace(value, "\\", "\\\\")).collect(Collectors.toSet())
        entry.setValue(modifiedSet)
      }
      Set<String> ldapGroupsSet = new HashSet<>();
      if (groupMapping.get(xWikiGroupName) != null) {
        ldapGroupsSet.addAll(groupMapping.get(xWikiGroupName))
      }
      ldapGroupsSet.addAll(ldapGroupsSetToAdd)
      groupMapping.put(xWikiGroupName, ldapGroupsSet)
      StringBuffer groupMappingStringBuffer = new StringBuffer()
      for (Entry<String, Set<String>> entry : groupMapping.entrySet()) {
        for (String ldapGroupDN : entry.getValue()) {
          groupMappingStringBuffer.append(entry.getKey()).append('=').append(ldapGroupDN).append("|");
        }
      }
      // Remove the last pipe separator from the mapping.
      String groupMappingString = StringUtils.chop(groupMappingStringBuffer.toString());
      def preferencesObject = configSourceDoc.getObject('XWiki.XWikiPreferences');
      preferencesObject.set("ldap_group_mapping", groupMappingString);
      configSourceDoc.save("Updated the LDAP group mapping by script - XNSUPPORT-9911");
    }
}
/////
if(request.confirm == 'true') {
  if(!hasProgramming){
    println('{{error}}You are not allowed to execute this script.{{/error}}');
    return;
  }
  XWikiLDAPConfig configuration = null;
  def ldapConfigProvider = services.component.getInstance(new DefaultParameterizedType(null, Provider.class, XWikiLDAPConfig.class))

  if (ldapConfigProvider != null && ldapConfigProvider.get() != null) {
    configuration = ldapConfigProvider.get();
  } else {
    // The default configuration retrieves the parameters set in the xwiki.properties file.
    configuration = new XWikiLDAPConfig(null);
  }
  LDAPDocumentHelper ldapDocumentHelper = services.component.getInstance(LDAPDocumentHelper.class)
  def user = configuration.getLDAPParam("ldap_bind_DN","");
  def password = configuration.getLDAPParam("ldap_bind_pass","");
  XWikiLDAPConnection connector = new XWikiLDAPConnection(configuration);
  connector.open(user, password, xcontext.getContext());

  XWikiLDAPUtils ldapUtils = new XWikiLDAPUtils(connector, configuration)
  def baseDN = configuration.getLDAPParam("ldap_base_DN", "");
  ldapUtils.setBaseDN(baseDN)
  ldapUtils.setUidAttributeName(configuration.getLDAPParam("ldap_UID_attr", "cn"));
  ldapUtils.setUserSearchFormatString(configuration.getLDAPParam("ldap_user_search_fmt", "({0}={1})"));
  def attributes = ['*'] as String[];

  //def groupsBaseDN = 'dc=swp-ldap,dc=internal'
  def ldapUserImportConfigObject = xwiki.getDocument('LDAPUserImport.WebHome').getObject('LDAPUserImport.LDAPUserImportConfigClass')
  def groupsBaseDN = ldapUserImportConfigObject.getProperty('ldapGroupImportSearchDN').getValue()
  def adminGroupDn = 'cn=managed-by-attribute-KnowledgemanagementAdmin,cn=groups,' + groupsBaseDN
  groupsFilter = ldapUserImportConfigObject.getProperty('ldapGroupImportSearchFilter').getValue()

  def results = connector.searchPaginated(groupsBaseDN, LDAPConnection.SCOPE_SUB, groupsFilter, attributes, false);
  if(results == null){
    println("Query returned null.")
  }
  else
  {
    def ldapGroupsMapping = [:]
    def iterated = false
    while (results.hasMore()) {
      iterated = true
      def entry = results.next()
      def dn = entry.getDN()
      def cn = entry.getAttribute('cn').getStringValue()
      if(dn != adminGroupDn){
        ldapGroupsMapping.put('xwiki:XWiki.' + cleanXWikiUserPageName(cn) + 'Group', [dn]);
      }
     }
    if (!iterated) {
      println('Query returned 0 results.')
    }
    results.close()
    // Recreate the mapping
    System.out.println("Recreating LDAP Group Mapping started")
    ldapGroupsMapping.each {xwikiGroup, ldapDN ->
      if(xwiki.exists(xwikiGroup)) {
        try {
          associateGroups(ldapDN.toArray(new String[0]), xwikiGroup, configuration)
          def msg = "Added mapping : ${xwikiGroup} -> ${ldapDN.get(0)}"
          System.out.println(msg)
          println('* ' + msg)
        }
        catch(Exception e){
          def msg = "Failed to add mapping : ${xwikiGroup} -> ${ldapDN.get(0)}"
          println('* ' + msg)
          System.out.println(msg)
          e.printStackTrace();
        }
      }
    }
    System.out.println("Recreating LDAP Group Mapping finished")
  }
}
else
{
  println "[[Recreate the LDAP Groups Mapping>>${doc.fullName}||queryString='confirm=true' class='button']]"
}
{{/groovy}}