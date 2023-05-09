import Float "mo:base/Float";

actor class Calculator() {
  var counter : Float = 0.0;

  public func add(x : Float) : async Float {
    counter := counter + x;
    counter;
  };

  public func sub(x : Float) : async Float {
    counter := counter - x;
    counter;
  };

  public func mul(x : Float) : async Float {
    counter := counter * x;
    counter;
  };

  public func div(x : Float) : async Float {
    if (x == 0.0) {
      return 0;
    };
    counter := counter / x;
    counter;
  };

  public func reset() : async () {
    counter := 0;
  };

  public query func see() : async Float {
    counter;
  };

  public func power(x : Float) : async Float {
    counter := counter ** x;
    counter;
  };

  public func sqrt() : async Float {
    counter ** 0.5;
  };

  public func floor() : async Int {
    counter := Float.floor(counter);
    Float.toInt(counter);
  };
};
