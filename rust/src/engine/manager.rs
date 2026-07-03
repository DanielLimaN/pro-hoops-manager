use serde::{Serialize, Deserialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct CoachProfile {
    pub id: u32,
    pub team_id: u32,
    pub name: String,
    pub focus: String,
    pub reputation: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Staff {
    pub id: u32,
    pub team_id: u32,
    pub name: String,
    pub role: String,
    pub skill_level: u32,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct InboxMessage {
    pub id: u32,
    pub coach_id: u32,
    pub sender_name: String,
    pub sender_role: String,
    pub subject: String,
    pub body: String,
    pub read: bool,
    pub date_received: String,
    pub action_required: bool,
}
