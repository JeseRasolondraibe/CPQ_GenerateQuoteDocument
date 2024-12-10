@isTest
public class QuoteTemplateGeneration_TEST {
    
    public class QuoteProposalModel {
        public String name;
        public Id quoteId;
        public Id templateId;
        public String language;
        public String outputFormat;
        public String paperSize;
    }
    
    @isTest(SeeAllData=true) 
    public static void processQuotes_TEST1() {
        Account account = UtilitiesForTestClass.createAccount();
        Opportunity opportunity = UtilitiesForTestClass.createOpportunity();
        opportunity.AccountId = account.Id;
        opportunity.Entite__c  = 'Soleil et Climat';
        insert opportunity;
        
        SBQQ__Quote__c quote = UtilitiesForTestClass.createCPQQuote();
        quote.SBQQ__Account__c = account.Id;
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        quote.SBQQ__Status__c = 'Approved';
        insert quote;
        
        // Stocker les devis dans une liste pour passer à la méthode processQuotes
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{quote};
        Map<Id, SBQQ__Quote__c> oldQuoteMap = new Map<Id, SBQQ__Quote__c>();
        
        QuoteProposalModel model = new QuoteProposalModel();
        model.quoteId = quote.Id;
        model.paperSize = 'A4';
        model.language = 'Default';
        model.templateId = Label.QT_SoleilClimat;
        
        Test.startTest(); 
        QuoteTemplateGeneration quo = new QuoteTemplateGeneration();
        String result1 = QuoteTemplateGeneration.processQuotes(quotes, oldQuoteMap);
        Test.stopTest();
    }
    
    @isTest(SeeAllData=true) 
    public static void publishEventAfterCPQDocumentGenerated_TEST(){
        Opportunity opportunity = UtilitiesForTestClass.createOpportunity();
        insert opportunity;
        
        SBQQ__Quote__c quote = UtilitiesForTestClass.createCPQQuote();
        quote.SBQQ__Opportunity2__c = opportunity.Id;
        Elements_controler__c element = UtilitiesForTestClass.createElementAControler();
        element.Dossier__c = opportunity.Id;
        insert element;
        
        ContentVersion contentVersion = UtilitiesForTestClass.createContentVersionImage();
        insert contentVersion;
        
        ContentDocumentLink cdl = UtilitiesForTestClass.createContentDocumentLink();
        cdl.LinkedEntityId = element.Id;
        cdl.contentdocumentid = [SELECT contentdocumentid FROM contentversion WHERE id =: contentVersion.id].contentdocumentid;
        insert cdl;
        
        List<ContentDocumentLink> ListCDL = new List<ContentDocumentLink>();
        ListCDL.add(cdl);
        
        SBQQ__QuoteDocument__c qteDoc = UtilitiesForTestClass.createCPQ_QuoteDocument();
        qteDoc.SBQQ__Quote__c = quote.Id;
        
        List<SBQQ__QuoteDocument__c> qteDocList = new List<SBQQ__QuoteDocument__c>();
        qteDocList.add(qteDoc);
        
        Test.startTest(); 
        QuoteTemplateGeneration quo = new QuoteTemplateGeneration();
        QuoteTemplateGeneration.publishEventAfterCPQDocumentGenerated(qteDocList);
        Test.stopTest();
    }
}