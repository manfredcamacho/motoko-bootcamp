import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Utils "Utils";
import IC "Ic";
import HTTP "Http";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;
  type Log = (eventType : Text, caller : Principal, paramPrincipal : ?Principal, paramCanister : ?Principal, profile : ?StudentProfile, event : Text);
  var logs = Buffer.Buffer<Log>(3);
  stable var entries : [(Principal, StudentProfile)] = [];
  let studentProfileStore = HashMap.fromIter<Principal, StudentProfile>(entries.vals(), 10, Principal.equal, Principal.hash);

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    try {
      studentProfileStore.put(caller, profile);
      logs.add(("addMyProfile - OK", caller, null, null, ?profile, ""));
      return #ok(());
    } catch (err) {
      logs.add(("addMyProfile - ERROR", caller, null, null, ?profile, Error.message(err)));
      return #err("Error adding profile: " # Error.message(err));
    };
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {

    let profileOption = studentProfileStore.get(p);
    switch (profileOption) {
      case (null) {
        logs.add(("seeAProfile - ERROR", caller, ?p, null, profileOption, "Profile not found"));
        return #err("Profile not found");
      };
      case (?profile) {
        logs.add(("seeAProfile - OK", caller, ?p, null, profileOption, ""));
        return #ok(profile);
      };
    };

  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (studentProfileStore.get(caller) == null) {
      logs.add(("updateMyProfile - ERROR", caller, null, null, ?profile, "Profile does not exist"));
      return #err("Profile does not exist");
    } else {
      studentProfileStore.put(caller, profile);
      logs.add(("updateMyProfile - OK", caller, null, null, ?profile, ""));
      return #ok(());
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    if (studentProfileStore.get(caller) == null) {
      logs.add(("deleteMyProfile - ERROR", caller, null, null, null, "Profile does not exist"));
      return #err("Profile does not exist");
    } else {
      logs.add(("deleteMyProfile - OK", caller, null, null, null, ""));
      studentProfileStore.delete(caller);
      return #ok(());
    };
  };

  // Allows to persist the data in the stable memory
  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    entries := [];
  };

  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  public shared ({ caller }) func test(canisterId : Principal) : async TestResult {
    try {
      let calculator = actor (Principal.toText(canisterId)) : calculatorInterface;

      ignore await calculator.reset();
      var result = await calculator.add(0);
      if (result != 0) {
        let msg = "Adding 0 to reset value should return 0 but returned " # Int.toText(result);
        logs.add(("test - ERROR - UnexpectedValue reset add 0", caller, null, ?canisterId, null, msg));
        return #err(#UnexpectedValue(msg));
      };

      result := await calculator.add(10);
      if (result != 10) {
        let msg = "Adding 10 should return 10 but returned " # Int.toText(result);
        logs.add(("test - ERROR - UnexpectedValue add 10", caller, null, ?canisterId, null, msg));
        return #err(#UnexpectedValue(msg));
      };

      result := await calculator.reset();
      if (result != 0) {
        let msg = "Reset should return 0 but returned " # Int.toText(result);
        logs.add(("test - ERROR - UnexpectedValue reset", caller, null, ?canisterId, null, msg));
        return #err(#UnexpectedValue(msg));
      };

      result := await calculator.sub(10);
      if (result != -10) {
        let msg = "Subtracting 10 should return -10 but returned " # Int.toText(result);
        logs.add(("test - ERROR - UnexpectedValue sub 10", caller, null, ?canisterId, null, msg));
        return #err(#UnexpectedValue(msg));
      };
      logs.add(("test - OK", caller, null, ?canisterId, null, ""));
      return #ok(());
    } catch (err) {
      let msg = "Unexpected error: " # Error.message((err));
      logs.add(("test - ERROR - Unexpected", caller, null, ?canisterId, null, msg));
      return #err(#UnexpectedError(msg));
    };
  };
  // STEP - 2 END

  // STEP 3 - BEGIN

  // NOTE: Not possible to develop locally,
  // as actor "aaaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  // As of today, the canister_status method of the management canister can only be used when
  // the canister calling it is also one of the controller of the canister you are trying to
  // check the status. Fortunately there is a trick to still get the controller! Read the
  // dedicated topic for more information.
  // https://forum.dfinity.org/t/getting-a-canisters-controller-on-chain/7531/17

  public shared ({ caller }) func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    let managementCanister = actor ("aaaaa-aa") : IC.ManagementCanisterInterface;
    try {
      let statusCanister = await managementCanister.canister_status({
        canister_id = canisterId;
      });
      let controllers = statusCanister.settings.controllers;
      let controllers_text = Array.map<Principal, Text>(controllers, func x = Principal.toText(x));
      switch (Array.find<Principal>(controllers, func x = p == x)) {
        case (?_) {
          logs.add(("verifyOwnership - OK", caller, ?p, ?canisterId, null, "TRY"));
          return true;
        };
        case null {
          logs.add(("verifyOwnership - ERROR", caller, ?p, ?canisterId, null, "TRY"));
          return false;
        };
      };
    } catch (e) {
      let message = Error.message(e);
      let controllers = Utils.parseControllersFromCanisterStatusErrorIfCallerNotController(message);
      let controllers_text = Array.map<Principal, Text>(controllers, func x = Principal.toText(x));
      switch (Array.find<Principal>(controllers, func x = p == x)) {
        case (?_) {
          logs.add(("verifyOwnership - OK", caller, ?p, ?canisterId, null, "CATCH"));
          return true;
        };
        case null {
          logs.add(("verifyOwnership - ERROR", caller, ?p, ?canisterId, null, "CATCH"));
          return false;
        };
      };
    };
  };

  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, principalId : Principal) : async Result.Result<(), Text> {
    let profileOption = studentProfileStore.get(principalId);
    switch (profileOption) {
      case (null) {
        logs.add(("verifyWork - ERROR", caller, ?principalId, ?canisterId, null, "Profile does not exist"));
        return #err("Profile does not exist");
      };
      case (?profile) {
        let isOwner = await verifyOwnership(canisterId, principalId);
        if (isOwner) {
          let workTestResult = await test(canisterId);
          switch (workTestResult) {
            case (#ok(())) {
              let updatedProfile = {
                name = profile.name;
                team = profile.team;
                graduate = true;
              };
              studentProfileStore.put(principalId, updatedProfile);
              logs.add(("verifyWork - OK", caller, ?principalId, ?canisterId, null, ""));
              return #ok();
            };
            case (#err(error)) {
              switch (error) {
                case (#UnexpectedValue(message)) {
                  logs.add(("verifyWork - ERROR", caller, ?principalId, ?canisterId, null, "Unexpected value: " # message));
                  return #err("Unexpected value: " # message);
                };
                case (#UnexpectedError(message)) {
                  logs.add(("verifyWork - ERROR", caller, ?principalId, ?canisterId, null, "Unexpected error: " # message));
                  return #err("Unexpected error: " # message);
                };
              };
            };
          };
        } else {
          logs.add(("verifyWork - ERROR", caller, ?principalId, ?canisterId, null, "Caller is not the owner of the canister "));
          return #err("Caller is not the owner of the canister");
        };
      };
    };
  };

  // public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
  //   logs.add(("verifyWork - CALL", caller, ?p, ?canisterId, null, ""));

  //   try {
  //     let isApproved = await test(canisterId);

  //     if (isApproved != #ok) {
  //       logs.add(("verifyWork - ERROR", caller, ?p, ?canisterId, null, "The current work has no passed the tests"));
  //       return #err("The current work has no passed the tests");
  //     };

  //     let isOwner = await verifyOwnership(canisterId, p);

  //     if (not isOwner) {
  //       logs.add(("verifyWork - ERROR", caller, ?p, ?canisterId, null, "The received work owner does not match with the received principal"));
  //       return #err("The received work owner does not match with the received principal");
  //     };

  //     var xProfile : ?StudentProfile = studentProfileStore.get(p);

  //     switch (xProfile) {
  //       case null {
  //         logs.add(("verifyWork - ERROR", caller, ?p, ?canisterId, null, "The received principal does not belongs to a registered student"));
  //         return #err("The received principal does not belongs to a registered student");
  //       };

  //       case (?profile) {
  //         var updatedStudent = {
  //           name = profile.name;
  //           graduate = true;
  //           team = profile.team;
  //         };

  //         ignore studentProfileStore.replace(p, updatedStudent);
  //         logs.add(("verifyWork - OK", caller, ?p, ?canisterId, null, ""));
  //         return #ok();
  //       };
  //     };
  //   } catch (e) {
  //     logs.add(("verifyWork - ERROR", caller, ?p, ?canisterId, null, "Cannot verify the project: " # Error.message(e)));
  //     return #err("Cannot verify the project");
  //   };
  // };

  // STEP 4 - END

  public shared ({ caller }) func _showPrincipal() : async Principal {
    return caller;
  };

  public shared func _showAllStudents() : async [(Principal, StudentProfile)] {
    Iter.toArray(studentProfileStore.entries());
  };

  public shared func _updateProfile(principal : Principal, profile : StudentProfile) : async Result.Result<(), Text> {
    if (studentProfileStore.get(principal) == null) {
      return #err("Profile does not exist");
    } else {
      studentProfileStore.put(principal, profile);
      return #ok(());
    };
  };
  public shared func _addProfile(principal : Principal, profile : StudentProfile) : async Result.Result<(), Text> {
    if (studentProfileStore.get(principal) != null) {
      return #err("Profile already exists");
    } else {
      studentProfileStore.put(principal, profile);
      return #ok(());
    };
  };
  public shared func _showLog() : async [Log] {
    Buffer.toArray(logs);
  };
  public shared func _clearLog() : async () {
    logs.clear();
  };
};
