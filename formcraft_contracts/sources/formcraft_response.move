#[allow(duplicate_alias)]
module formcraft_contracts::forms {
    // Import necessary modules and members
    use sui::object::{Self, UID}; // Import Self and UID explicitly
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::Option;
    use std::vector;
    use std::string::String;

    const ENotOwner: u64 = 0;
    const EQuestionAnswerMismatch: u64 = 1;
    const EAlreadyAnswered: u64 = 2;

    /// Represents a single question in the form
    public struct Question has store {
        id: String,
        type_: String,
        question: String,
        options: Option<vector<String>>,
        answers: Table<address, String>
    }

    /// Represents a form with its metadata and questions
    public struct Form has key, store {
        id: UID,
        owner: address,
        audience: String,
        data_type: String,
        purpose: String,
        demographic: String,
        questions: vector<Question>,
    }

    /// Maps respondents to a specific form
    public struct RespondentMapping has key, store {
        id: UID,
        form_id: UID,
        respondents: vector<address>,
    }

    /// Module initializer
    fun init(_ctx: &mut TxContext) {
        // No initialization logic required for this module
    }

    /// Create a new form
    public fun create_form(
        audience: String,
        data_type: String,
        purpose: String,
        demographic: String,
        questions: vector<Question>,
        ctx: &mut TxContext,
    ): Form {
        let form = Form {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            audience,
            data_type,
            purpose,
            demographic,
            questions,
        };
        
        // Transfer ownership of the form
        transfer::public_share_object(form);
        
        // Return a new instance of the form
        Form {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            audience,
            data_type,
            purpose,
            demographic, 
            questions: vector::empty(), // New instance with empty questions
        }
    }

    /// Add a respondent to a form
    public fun add_respondent(
        mapping: &mut RespondentMapping,
        respondent: address,
    ) {
        vector::push_back(&mut mapping.respondents, respondent);
    }

    /// Create a new respondent mapping for a form
    public fun create_respondent_mapping(
        form_id: UID,
        ctx: &mut TxContext,
    ): RespondentMapping {
        RespondentMapping {
            id: object::new(ctx),
            form_id,
            respondents: vector::empty(),
        }
    }

    /// Helper function to create a new question
    public fun create_question(
        id: String,
        type_: String,
        question: String,
        options: Option<vector<String>>,
        ctx: &mut TxContext
    ): Question {
        // Create the table for answers
        let answers = table::new(ctx);
        
        Question {
            id,
            type_,
            question,
            options,
            answers,
        }
    }

    public fun add_question(
        form: &mut Form,
        question: Question,
        ctx: &TxContext
    ) {
        assert!(tx_context::sender(ctx) == form.owner, ENotOwner);
        vector::push_back(&mut form.questions, question);
    }

    public fun submit_answer(
        form: &mut Form,
        answers: vector<String>,
        ctx: &TxContext
    ) {
       assert!(vector::length(&form.questions) == vector::length(&answers), EQuestionAnswerMismatch);
       let mut i = 0; // Mutable index for iteration
       while(i < vector::length(&answers)) {
            let question = vector::borrow_mut(&mut form.questions, i);
            assert!(!table::contains(&question.answers, tx_context::sender(ctx)), EAlreadyAnswered);
            table::add(
                &mut question.answers,
                tx_context::sender(ctx),
                *vector::borrow(&answers, i)
            );
            i = i + 1;
       }
    }

    /// Get the owner of a form
    public fun get_owner(form: &Form): address {
        form.owner
    }

    /// Get the questions of a form
    public fun get_questions(form: &Form): &vector<Question> {
        &form.questions
    }

    /// Get the respondents of a form
    public fun get_respondents(mapping: &RespondentMapping): &vector<address> {
        &mapping.respondents
    }
}