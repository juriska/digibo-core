#include "appctx.h"

QString appctx_t::get_doc_status(int value)
{
	switch (value)
	{
	case doc_status_t::Executed:
		return tr("Executed");
	case doc_status_t::InvSignature:
		return tr("Invalid signature");
	case doc_status_t::Rejected:
		return tr("Rejected");
	case doc_status_t::Delivered:
		return tr("Delivered");
	case doc_status_t::SignOK:
		return tr("Signature Ok");
	case doc_status_t::Draft:
		return tr("Draft");
	case doc_status_t::AnswPending:
		return tr("Answer pending");
	case doc_status_t::Printed:
		return tr("Printed");
	case doc_status_t::SignChkPending:
		return tr("Signature check pending");
	case doc_status_t::ConfirmOK:
		return tr("Confirm OK");
	case doc_status_t::MsgGenerated:
		return tr("Message generated");
	case doc_status_t::MsgSent:
		return tr("Message sent");
	case doc_status_t::PartlyExec:
		return tr("Partly executed");
	case doc_status_t::Processing:
	case doc_status_t::WaitingPersonalDataCheck:
	case doc_status_t::PersonalDataManualCompare:
		return tr("Processing");
	case doc_status_t::BankT:
		return tr("Bank template");
	case doc_status_t::UserT:
		return tr("User template");
	case doc_status_t::Reversed:
		return tr("Reversed");
	case doc_status_t::Maturity:
		return tr("Maturity");
	case doc_status_t::MsgPending:
		return tr("Message pending");
	case doc_status_t::MsgFailed:
		return tr("Message failed");
	case doc_status_t::MsgGeneratedRejected:
		return tr("Message rejected");
	case doc_status_t::MsgGeneratedReversed:
		return tr("Message reversed");
	case doc_status_t::PartlySucceed:
		return tr("Partly Succeed");
	case doc_status_t::AwaitingProcessing:
		return tr("Awaiting processing");
	case doc_status_t::SignatureAdditional:
		return tr("Additional signature is required");
	case doc_status_t::SignatureRejected:
		return tr("Signature rejected");
	case doc_status_t::DraftValidated:
		return tr("Draft");
	case doc_status_t::ValidatedGlbWaiting:
		return tr("Loan offer order after validate status");
	case doc_status_t::GlobusApproved:
		return tr("Loan offer order status if GLOBUS is approved order");
	case doc_status_t::SignatureOKFirstCoborrower:
		return tr("First coborrower signature received");
	case doc_status_t::TemplateShared:
		return tr("Template shared");
	case doc_status_t::WaitingForApproval:
		return tr("Waiting for approval");
	case doc_status_t::ProcessingApproval:
		return tr("Processing approval");
	case doc_status_t::WaitingForAuth:
		return tr("Waiting for auth");
	case doc_status_t::ProcessingAuth:
		return tr("Processing auth");
	case doc_status_t::RequireLursoftCheck:
		return tr("Require Lursoft check");
	case doc_status_t::OperatorConfirmOK:
		return tr("Operator confirm Ok");
	case doc_status_t::RejectedByVeriff:
		return tr("Rejected by Veriff");
	case doc_status_t::DeliveredGenesys:
		return tr("Delivered Genesys");
	case doc_status_t::RejectedByOndato:
		return tr("Rejected by Ondato");
		// case 16:	return tr("Partly executed");
	}
	return value ? tr("Document status id %1").arg(value) : QString::null;
}
