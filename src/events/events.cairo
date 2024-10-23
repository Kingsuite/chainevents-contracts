#[starknet::contract]
pub mod Events {
    use core::num::traits::zero::Zero;
    use chainevents_contracts::base::types::{EventDetails, EventRegistration, EventType};
    use chainevents_contracts::base::errors::Errors::{
        ZERO_ADDRESS_OWNER, ZERO_ADDRESS_CALLER, NOT_OWNER
    };
    use chainevents_contracts::interfaces::IEvent::IEvent;
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry}
    };

    #[storage]
    struct Storage {
        // new_events: Map<u256, EventDetails>, // map <eventId, EventDetailsParams>
        // event_counts: u256,
        // registered_events: Map<
        //     u256, Map<u256, ContractAddress>
        // >, // map <eventId, RegisteredUser Address>
        // event_attendances: Map<u256, ContractAddress>, //  map <eventId, RegisteredUser Address>

        // STORAGE MAPPING REFACTOR
        event_owners: Map<u256, ContractAddress>, // map(event_id, eventOwnerAddress)
        event_counts: u256,
        event_details: Map<u256, EventDetails>, // map(event_id, EventDetailsParams)
        event_registrations: Map<ContractAddress, u256>, // map<attendeeAddress, event_id>
        attendee_event_details: Map<
            (u256, ContractAddress), EventRegistration
        >, // map <(event_id, attendeeAddress), EventRegistration>
        paid_events: Map<
            (ContractAddress, u256), u256
        > // map<(attendeeAddress, event_id), amount_paid>
    }

    // event
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        NewEventAdded: NewEventAdded,
        RegisteredForEvent: RegisteredForEvent,
        EventAttendanceMark: EventAttendanceMark,
        UpgradedEvent: UpgradedEvent,
        EndEventRegistration: EndEventRegistration,
        RSVPForEvent: RSVPForEvent
    }

    #[derive(Drop, starknet::Event)]
    pub struct NewEventAdded {
        pub name: ByteArray,
        pub event_id: u256,
        pub location: ByteArray,
        pub event_owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct RegisteredForEvent {
        event_id: u256,
        event_name: felt252,
        user_address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct EndEventRegistration {
        event_id: u256,
        event_name: felt252,
        event_owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct RSVPForEvent{
        event_id: u256,
        event_name: felt252,
        attendee_address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct UpgradedEvent{
        event_id: u256,
        event_name: felt252,
        paid_amount: u256,
        event_type: EventType
    }


    #[derive(Drop, starknet::Event)]
    struct EventAttendanceMark {
        event_id: u256,
        user_address: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.event_counts.write(0)
    }

    #[abi(embed_v0)]
    impl EventsImpl of IEvent<ContractState> {
        fn add_event(ref self: ContractState, name: ByteArray, location: ByteArray) -> u256 {
            let event_owner = get_caller_address();
            let event_id = self.event_counts.read() + 1;
            let event_name = name.clone();
            let event_location = location.clone();

            let event_details = EventDetails {
                event_id: event_id,
                name: event_name,
                location: event_location,
                organizer: event_owner,
                total_register: 0,
                total_attendees: 0,
                event_type: EventType::Free,
                is_closed: false,
                paid_amount: 0,
            };

            // save the event details
            self.event_details.write(event_id, event_details);

            // save event owner
            self.event_owners.write(event_id, event_owner);

            // emit event
            self
                .emit(
                    NewEventAdded {
                        event_id: event_id,
                        name: name,
                        location: location,
                        event_owner: event_owner,
                    }
                );
            event_id
        }
        fn register_for_event(ref self: ContractState, event_id: u256, event_fee: u256) {}
        fn end_event_registration(
            ref self: ContractState, event_id: u256
        ) {} // only owner can closed an event 
        fn rsvp_for_event(ref self: ContractState, event_id: u256) {}
        fn upgrade_event(ref self: ContractState, event_id: u256, paid_amount: u256) {}

        // GETTER FUNCTION
        fn event_details(self: @ContractState, event_id: u256) -> EventDetails {
            let event_detail = self.event_details.read(event_id);
            let event_details = EventDetails {
                event_id: 1,
                name: event_detail.name,
                location: event_detail.location,
                organizer: get_caller_address(),
                total_register: 1,
                total_attendees: 2,
                event_type: EventType::Free,
                is_closed: false,
                paid_amount: 0,
            };
            event_details
        }
        fn event_owner(self: @ContractState, event_id: u256) -> ContractAddress {
            get_caller_address()
        }
        fn attendee_event_details(self: @ContractState, event_id: u256) -> EventRegistration {
            let event_attendance_details = EventRegistration {
                attendee_address: get_caller_address(),
                amount_paid: 34,
                has_rsvp: true,
                nft_contract_address: get_caller_address(),
                nft_token_id: 34,
                organizer: get_caller_address()
            };
            event_attendance_details
        }
    }
}