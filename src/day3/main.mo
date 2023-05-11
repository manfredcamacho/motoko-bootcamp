import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Int "mo:base/Int";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  func _natHash(n : Nat) : Hash.Hash {
    Text.hash(Nat.toText(n));
  };

  var messageIdCounter : Nat = 0;
  let wall : HashMap.HashMap<Nat, Message> = HashMap.HashMap<Nat, Message>(1, Nat.equal, _natHash);

  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let id = messageIdCounter;
    messageIdCounter := messageIdCounter + 1;
    let message : Message = { vote = 0; content = c; creator = caller };
    wall.put(id, message);
    return id;
  };

  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let message = wall.get(messageId);
    switch (message) {
      case (?value) { #ok(value) };
      case (null) { #err("Message not found") };
    };
  };

  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    let message = wall.get(messageId);
    switch (message) {
      case (?value) {
        if (value.creator == caller) {
          let newMessage : Message = {
            vote = value.vote;
            content = c;
            creator = caller;
          };
          wall.put(messageId, newMessage);
          #ok(());
        } else {
          #err("You are not the creator of this message");
        };
      };
      case (null) { #err("Message not found") };
    };
  };

  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let message = wall.get(messageId);
    switch (message) {
      case (?_) {
        wall.delete(messageId);
        #ok(());
      };
      case (null) { #err("Message not found") };
    };
  };

  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    addVote(messageId, 1);
  };

  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    addVote(messageId, -1);
  };

  private func addVote(messageId : Nat, vote : Int) : Result.Result<(), Text> {
    let message = wall.get(messageId);
    switch (message) {
      case (?value) {
        let newMessage : Message = {
          vote = value.vote + vote;
          content = value.content;
          creator = value.creator;
        };
        wall.put(messageId, newMessage);
        #ok(());
      };
      case (null) { #err("Message not found") };
    };
  };

  public func getAllMessages() : async [Message] {
    Iter.toArray(wall.vals());
  };

  public func getAllMessagesRanked() : async [Message] {
    let messages = Iter.toArray(wall.vals());
    let result = Array.sort<Message>(
      messages,
      compareMsg,
    );
    result;
  };

  private func compareMsg(msg1 : Message, msg2 : Message) : Order.Order {
    // Order descending by vote
    Int.compare(msg2.vote, msg1.vote);
  };

};
