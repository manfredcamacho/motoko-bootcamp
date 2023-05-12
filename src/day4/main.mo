import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Account "Account";

// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";
import Principal "mo:base/Principal";

actor class MotoCoin() {

  let ledger : TrieMap.TrieMap<Account, Nat> = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  //This Canister is a bootcamp actor on the IC
  let bootcampICActor = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
  };

  public type Account = Account.Account;

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var total = 0;
    for (balance in ledger.vals()) {
      total += balance;
    };
    total;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    return Option.get(ledger.get(account), 0);
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    let senderBalance = Option.get(ledger.get(from), 0);
    let receiverBalance = Option.get(ledger.get(to), 0);
    if (senderBalance < amount) {
      return #err("Not enough funds");
    };
    ledger.put(from, senderBalance - amount);
    ledger.put(to, receiverBalance + amount);
    return #ok(());
  };

  public func getAccounts() : async [Principal] {
    let bootcampActor = await BootcampLocalActor.BootcampLocalActor(); //Local
    let principals = await bootcampActor.getAllStudentsPrincipal();
    principals;
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {

    // let bootcampActor = bootcampICActor; //IC
    let bootcampActor = await BootcampLocalActor.BootcampLocalActor(); //Local

    let principals = await bootcampActor.getAllStudentsPrincipal();

    for (principal in Iter.fromArray(principals)) {
      let account = {
        owner = principal;
        subaccount = null;
      };

      let balance = Option.get(ledger.get(account), 0);
      ledger.put(account, balance + 100);
    };
    return #ok(());
  };
};
