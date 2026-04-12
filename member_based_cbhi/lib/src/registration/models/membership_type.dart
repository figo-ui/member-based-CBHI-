enum MembershipType {
  indigent,
  paying,
}

class MembershipSelection {
  final MembershipType type;
  final double? premiumAmount; // For paying members

  MembershipSelection({required this.type, this.premiumAmount});
}