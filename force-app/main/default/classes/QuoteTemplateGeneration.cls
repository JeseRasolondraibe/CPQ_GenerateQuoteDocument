public class QuoteTemplateGeneration {
    
    public with sharing class GenerateQuoteProposal {
        
        public String save(QuoteProposalModel context) {
            if(!Test.isRunningTest()){
                return SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', JSON.serialize(context)); 
            } else {
                AsyncApexJob asyncJob = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'QueueableQuoteDocumentService' ORDER BY CreatedDate DESC LIMIT 1];
                if (asyncJob != null) {
                    // Stockez l'ID dans la variable de type chaîne
                    String jobId = asyncJob.Id;
                    return jobId;
                } else {
                    return 'No result';
                }
            }
        }
    }
    
    public class QuoteProposalModel {
        public String name;
        public Id quoteId;
        public Id templateId;
        public String language;
        public String outputFormat;
        public String paperSize;
    }
    
    
    public static String processQuotes(List<SBQQ__Quote__c> newQuotes, Map<Id, SBQQ__Quote__c> oldQuoteMap) {
        String concatenatedJobIds = '';
        
        for (SBQQ__Quote__c newQuote : newQuotes) {
            SBQQ__Quote__c oldQuote = oldQuoteMap.get(newQuote.Id);
            
            if (newQuote.SBQQ__Status__c == 'Approved' && (oldQuote == null || oldQuote.SBQQ__Status__c != 'Approved')) {
                QuoteProposalModel model = new QuoteProposalModel();
                model.quoteId = newQuote.Id;
                model.paperSize = 'A4';
                model.language = 'Default';
                
                // Determine the templateId based on specific condition
                if (newQuote.EntiteFromOppty__c == 'Soleil et Climat') {
                    model.templateId = Label.QT_SoleilClimat;
                } else if(newQuote.EntiteFromOppty__c == 'Chauffage et Climat'){
                    model.templateId = Label.QT_ChauffageClimat;
                } else if(newQuote.EntiteFromOppty__c == 'Façades et Climat'){
                    model.templateId = Label.QT_FacadeClimat;
                }
                
                // Call the method to save the quote and get the job ID
                GenerateQuoteProposal proposalGenerator = new GenerateQuoteProposal();
                String jobId = proposalGenerator.save(model);
                
                // Concatenate the job IDs
                concatenatedJobIds += jobId + ';';
            }
        }
        
        // Remove the trailing ';' if it exists
        if (concatenatedJobIds.endsWith(';')) {
            concatenatedJobIds = concatenatedJobIds.removeEnd(';');
        }
        
        return concatenatedJobIds;
    }
    
    public static void publishEventAfterCPQDocumentGenerated(List<SBQQ__QuoteDocument__c > newQuoteDocuments) {
        List<QuoteDocumentCreated__e> events = new List<QuoteDocumentCreated__e>();
        
        for (SBQQ__QuoteDocument__c qte : newQuoteDocuments) {
            QuoteDocumentCreated__e event = new QuoteDocumentCreated__e();
            event.RecordId__c = qte.Id;
            event.QuoteId__c = qte.SBQQ__Quote__c ;
            
            events.add(event);
        }
        
        if (!events.isEmpty()) {
            PublishEventCPQQuoteDocument(events);
        }
    }
    
    private static void PublishEventCPQQuoteDocument(List<QuoteDocumentCreated__e> events) {
        EventBus.publish(events);
    }
}