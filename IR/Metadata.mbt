///|
pub trait Metadata: Show {
  fn asMetadataEnum(Self) -> MetadataEnum
}

///|
pub enum MetadataEnum {
  MDString(MDString)
  MDNode(MDNode)
}

// =================================================
// MDString
// =================================================

// Only Context has ability to create MDString instances.

///|
pub struct MDString {

  // MDString is unique. So it has an ID.
  str : String
}

///|
pub impl Metadata for MDString with fn asMetadataEnum(self) {
  MDString(self)
}

///|
pub impl Show for MDString with fn output(self, logger) {
  logger.write_string("!\"\{self.str}\"")
}

// =================================================
// MDNode
// =================================================

///|
pub struct MDNode {
  // MDNode is a collection of Metadata.
  // It can contain any number of MetadataEnum.
  metadata : Array[&Metadata]
}

///|
pub impl Metadata for MDNode with fn asMetadataEnum(self) {
  MDNode(self)
}

///|
pub impl Show for MDNode with fn output(self, logger) {
  let metadata_strs = self.metadata.map(m => Show::to_string(m))
  let metadata_joined = metadata_strs.join(", ")
  logger.write_string("!{\{metadata_joined}}")
}

// =================================================
// MDAttachments
// =================================================

///|
priv struct MDAttachments {
  attachments : Array[(String, MDNode)]
}

///|
/// FIXME: eliminate this function.
/// This is only for eliminate warning.
pub fn warning_elimination() -> Unit {
  MDNode::{ metadata: [], } |> ignore()
  let mda = MDAttachments::{ attachments: [], }
  mda.attachments.length() |> ignore()
}
