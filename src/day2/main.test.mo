import Debug "mo:base/Debug";
import Time "mo:base/Time";
import MoSpec "mo:mospec/MoSpec";

import Main "main";
import Type "Types";
import Text "mo:base/Text";

let day2Actor = await Main.Homework();

let assertTrue = MoSpec.assertTrue;
let describe = MoSpec.describe;
let context = MoSpec.context;
let before = MoSpec.before;
let it = MoSpec.it;
let skip = MoSpec.skip;
let pending = MoSpec.pending;
let run = MoSpec.run;

let homeworkTest : Type.Homework = {
  title = "Test";
  description = "Test";
  dueDate = Time.now();
  completed = false;
};

let success = run([
  describe(
    "#addHomework",
    [
      it(
        "should add a Homework to Diary",
        do {
          let id = await day2Actor.addHomework(homeworkTest);
          assertTrue(id == 0);
        },
      ),
      it(
        "Should have 1 homework",
        do {
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 1);
        },
      ),
    ],
  ),
  describe(
    "#getHomework",
    [
      it(
        "should get a Homework by Id",
        do {
          let response = await day2Actor.getHomework(0);
          switch (response) {
            case (#ok(homework)) {
              assertTrue(homework.title == homeworkTest.title);
            };
            case (#err(message)) {
              Debug.trap("Homework not found");
            };
          };
        },
      ),
    ],
  ),
  describe(
    "#updateHomework",
    [
      it(
        "should update an existent Homework",
        do {
          ignore await day2Actor.addHomework(homeworkTest);
          let homeworkTest2 : Type.Homework = {
            title = "Test2";
            description = "Test";
            dueDate = Time.now();
            completed = false;
          };
          let response = await day2Actor.updateHomework(1, homeworkTest2);
          switch (response) {
            case (#ok(_)) {
              true;
            };
            case (#err(message)) {
              Debug.trap("Homework not found");
            };
          };
        },
      ),
      it(
        "Should have 2 homeworks and just one updated",
        do {
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 2 and response[1].title == "Test2");
        },
      ),
    ],
  ),
  describe(
    "#markAsCompleted",
    [
      it(
        "should mark 1 homework as complete",
        do {
          ignore await day2Actor.addHomework(homeworkTest);
          let response = await day2Actor.markAsCompleted(1);
          switch (response) {
            case (#ok) {
              true;
            };
            case (#err(message)) {
              Debug.trap("Homework not found");
            };
          };
        },
      ),
      it(
        "Should have 3 homeworks and just one marked as completed",
        do {
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 3 and response[1].completed);
        },
      ),
    ],
  ),
  describe(
    "#deleteHomework",
    [
      it(
        "should delete an existent Homework",
        do {
          let response = await day2Actor.deleteHomework(0);
          switch (response) {
            case (#ok) {
              true;
            };
            case (#err(message)) {
              Debug.trap("Homework not found");
            };
          };
        },
      ),
      it(
        "Should have 2 homework",
        do {
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 2);
        },
      ),
    ],
  ),
  describe(
    "#getAllHomework",
    [
      it(
        "should get all Homeworks",
        do {
          ignore await day2Actor.addHomework(homeworkTest);
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 3);
        },
      ),
    ],
  ),
  describe(
    "#getPendingHomework",
    [
      it(
        "Should have 3 homeworks",
        do {
          let response = await day2Actor.getAllHomework();
          assertTrue(response.size() == 3);
        },
      ),
      it(
        "should get 2 Homework not completed",
        do {
          let response = await day2Actor.getPendingHomework();
          assertTrue(response.size() == 2);
        },
      ),
    ],
  ),
  describe(
    "#searchHomework",
    [
      it(
        "should return 3 matchs of term with title or description `Test`",
        do {
          let response = await day2Actor.searchHomework("Test");
          assertTrue(response.size() == 3);
        },
      ),
      it(
        "should return 1 matchs of term with title or description `Test2`",
        do {
          let response = await day2Actor.searchHomework("Test2");
          assertTrue(response.size() == 1);
        },
      ),
    ],
  ),
]);

if (success == false) {
  Debug.trap("Tests failed");
};
