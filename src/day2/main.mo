import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Type "Types";
import Debug "mo:base/Debug";

actor class Homework() {
  type Homework = Type.Homework;
  let homeworkDiary = Buffer.Buffer<Homework>(5);

  public shared func addHomework(homework : Homework) : async Nat {
    homeworkDiary.add(homework);
    return homeworkDiary.size() - 1;
  };

  public shared query func getHomework(id : Nat) : async Result.Result<Homework, Text> {
    let homework = homeworkDiary.getOpt(id);
    switch homework {
      case null #err("Homework not found");
      case (?currentHomework) #ok(currentHomework);
    };
  };

  public shared func updateHomework(id : Nat, homework : Homework) : async Result.Result<(), Text> {
    let result = await getHomework(id);
    switch (result) {
      case (#ok(_)) {
        homeworkDiary.put(id, homework);
        return #ok(());
      };
      case (#err(failure)) {
        return #err(failure);
      };
    };
  };

  public shared func markAsCompleted(id : Nat) : async Result.Result<(), Text> {
    let result = await getHomework(id);
    switch (result) {
      case (#ok(homework)) {
        let updatedHomework : Homework = {
          completed = true;
          description = homework.description;
          dueDate = homework.dueDate;
          title = homework.title;
        };
        await updateHomework(id, updatedHomework);
      };
      case (#err(failure)) {
        return #err(failure);
      };
    };
  };

  public shared func deleteHomework(id : Nat) : async Result.Result<(), Text> {
    try {
      ignore homeworkDiary.remove(id);
      return #ok(());
    } catch (e) {
      return #err("Homework not found");
    };

  };

  public shared query func getAllHomework() : async [Homework] {
    Buffer.toArray(homeworkDiary);
  };

  public shared query func getPendingHomework() : async [Homework] {
    let homeworkArray = Buffer.toArray(homeworkDiary);
    Array.filter(
      homeworkArray,
      func(homework : Homework) : Bool {
        homework.completed == false;
      },
    );
  };

  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    let homeworkArray = Buffer.toArray(homeworkDiary);
    let pattern = #text searchTerm;
    Array.filter(
      homeworkArray,
      func(homework : Homework) : Bool {
        let titleMatch = Text.contains(homework.title, pattern);
        let descriptionMatch = Text.contains(homework.description, pattern);
        titleMatch or descriptionMatch;
      },
    );
  };
};
