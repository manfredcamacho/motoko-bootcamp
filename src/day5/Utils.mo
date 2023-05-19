import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";

module {
    public func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : [Principal] {
        let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
        let words = Iter.toArray(Text.split(lines[1], #text(" ")));
        var i = 2;
        let controllers = Buffer.Buffer<Principal>(0);
        while (i < words.size()) {
            controllers.add(Principal.fromText(words[i]));
            i += 1;
        };
        Buffer.toArray<Principal>(controllers);
    };
};
