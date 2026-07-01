import Foundation

// Enums espejo de los tipos de Postgres (ver SCHEMA.md).
// Los raw values coinciden 1:1 con los valores del enum en la BD.

enum UserRole: String, Codable, CaseIterable, Sendable {
    case atleta, coach, admin

    var displayName: String {
        switch self {
        case .atleta: "Atleta"
        case .coach: "Coach"
        case .admin: "Administrador"
        }
    }
}

enum AthleteLevel: String, Codable, CaseIterable, Sendable {
    case basico, intermedio, avanzado

    var displayName: String {
        switch self {
        case .basico: "Básico"
        case .intermedio: "Intermedio"
        case .avanzado: "Avanzado"
        }
    }
}

enum RxLevel: String, Codable, CaseIterable, Sendable {
    case rx, escalado

    var displayName: String {
        switch self {
        case .rx: "RX"
        case .escalado: "Escalado"
        }
    }
}

enum ScoreType: String, Codable, CaseIterable, Sendable {
    case peso, tiempo, reps, rondas, distancia, calorias
}

enum ResultStatus: String, Codable, CaseIterable, Sendable {
    case pendiente, validado, corregido
}

enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case fuerza, gimnasia, endurance, movilidad, olimpico

    var displayName: String {
        switch self {
        case .fuerza: "Fuerza"
        case .gimnasia: "Gimnasia"
        case .endurance: "Endurance"
        case .movilidad: "Movilidad"
        case .olimpico: "Olímpico"
        }
    }
}

enum WodType: String, Codable, CaseIterable, Sendable {
    case amrap, emom, tabata, fuerza, running, hiit
    case forTime = "for_time"

    var displayName: String {
        switch self {
        case .amrap: "AMRAP"
        case .emom: "EMOM"
        case .forTime: "FOR TIME"
        case .tabata: "TABATA"
        case .fuerza: "Fuerza"
        case .running: "Running"
        case .hiit: "HIIT"
        }
    }
}

enum WodStatus: String, Codable, CaseIterable, Sendable {
    case borrador, publicado, archivado
}

enum BlockType: String, Codable, CaseIterable, Sendable {
    case calentamiento, fuerza, metcon, skill, accesorio

    var displayName: String {
        switch self {
        case .calentamiento: "Calentamiento"
        case .fuerza: "Fuerza / Técnica"
        case .metcon: "Metcon"
        case .skill: "Skill"
        case .accesorio: "Accesorio"
        }
    }
}

enum BodyZone: String, Codable, CaseIterable, Sendable {
    case cabeza, hombros, espalda, codos, munecas, lumbar, cadera, rodillas, tobillos

    var displayName: String {
        switch self {
        case .munecas: "Muñecas"
        default: rawValue.capitalized
        }
    }
}

enum InjurySeverity: String, Codable, CaseIterable, Sendable {
    case leve, moderada, severa
}

enum InjuryStatus: String, Codable, CaseIterable, Sendable {
    case activa
    case enSeguimiento = "en_seguimiento"
    case resuelta
}

enum NoteCategory: String, Codable, CaseIterable, Sendable {
    case general, performance, lesion, nutricion
}

enum NoteVisibility: String, Codable, CaseIterable, Sendable {
    case soloCoach = "solo_coach"
    case compartida
}

enum AttendanceStatus: String, Codable, CaseIterable, Sendable {
    case presente, ausente, tarde
}

enum ChallengeType: String, Codable, CaseIterable, Sendable {
    case comunidad, individual
}

enum NotificationType: String, Codable, CaseIterable, Sendable {
    case validacion, lesion, asistencia, mensaje, logro, general
}
