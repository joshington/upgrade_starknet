//starknet separates contracts into classes and instances, making it simple to upgrade a contract's
//logic without affecting its state.

//contract class => defn of the semantics of a contract. => includes entire logic of a  contract
//==the name of the entry points, addresses of the storage variables
//events that can be emitted
//==each class is uniquely identified by its class hash
//==a class does not have its own storage; its only a definition of logic.
//when declaring a class, the network registers it and assigns a unique hash used to identify the class
//and deloy contract instances from it.
//==contract instance is a deployed contract corresponding to aclass with its own storage.

#[starknet::contract]
mod UpgradeableContract {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::ClassHash;
    use starknet::ContractAddress;

    component!(path: OwnableComponent, storage:ownable , event:OwnableEvent);
    component!(path: UpgradeableComponent, storage:upgradeable , event:UpgradeableEvent );

    //Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    //upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage 
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent:OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            //function can only be called by the owner
            self.ownable.assert_only_owner();

            //replace the class hash upgrading the contract
            self.upgradeable._upgrade(new_class_hash);
        }
    }
}