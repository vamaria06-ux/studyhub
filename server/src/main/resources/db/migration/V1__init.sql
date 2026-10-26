CREATE TABLE semester (
                          id          BIGSERIAL PRIMARY KEY,
                          name        VARCHAR(50) NOT NULL,
                          start_date  DATE NOT NULL,
                          end_date    DATE NOT NULL,
                          created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                          CONSTRAINT semester_dates_chk CHECK (end_date > start_date)
);

CREATE TABLE academic_event (
                                id           BIGSERIAL PRIMARY KEY,
                                semester_id  BIGINT NOT NULL REFERENCES semester(id) ON DELETE CASCADE,
                                title        VARCHAR(200) NOT NULL,
                                type         VARCHAR(20) NOT NULL,
                                start_date   DATE NOT NULL,
                                end_date     DATE NOT NULL,
                                CONSTRAINT academic_event_type_chk  CHECK (type IN ('SESSION','HOLIDAY','CREDIT_WEEK','DAY_OFF','OTHER')),
                                CONSTRAINT academic_event_dates_chk CHECK (end_date >= start_date)
);

CREATE TABLE teacher (
                         id          BIGSERIAL PRIMARY KEY,
                         full_name   VARCHAR(200) NOT NULL,
                         email       VARCHAR(200),
                         created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE course (
                        id               BIGSERIAL PRIMARY KEY,
                        semester_id      BIGINT NOT NULL REFERENCES semester(id) ON DELETE RESTRICT,
                        name             VARCHAR(200) NOT NULL,
                        short_name       VARCHAR(30),
                        color            CHAR(7),
                        assessment_type  VARCHAR(20) NOT NULL DEFAULT 'EXAM',
                        archived         BOOLEAN NOT NULL DEFAULT false,
                        created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
                        CONSTRAINT course_color_chk      CHECK (color ~ '^#[0-9A-Fa-f]{6}$'),
    CONSTRAINT course_assessment_chk CHECK (assessment_type IN ('EXAM','DIFF_CREDIT','CREDIT'))
);

CREATE TABLE course_teacher (
                                course_id   BIGINT NOT NULL REFERENCES course(id)  ON DELETE CASCADE,
                                teacher_id  BIGINT NOT NULL REFERENCES teacher(id) ON DELETE CASCADE,
                                role        VARCHAR(20) NOT NULL,
                                PRIMARY KEY (course_id, teacher_id, role),
                                CONSTRAINT course_teacher_role_chk CHECK (role IN ('LECTURER','PRACTICE','LAB'))
);

CREATE TABLE course_link (
                             id          BIGSERIAL PRIMARY KEY,
                             course_id   BIGINT NOT NULL REFERENCES course(id) ON DELETE CASCADE,
                             title       VARCHAR(200) NOT NULL,
                             url         TEXT NOT NULL,
                             kind        VARCHAR(20) NOT NULL DEFAULT 'OTHER',
                             created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
                             CONSTRAINT course_link_kind_chk CHECK (kind IN ('LMS','CHAT','DRIVE','VIDEO','REPO','OTHER'))
);

CREATE TABLE task (
                      id            BIGSERIAL PRIMARY KEY,
                      course_id     BIGINT NOT NULL REFERENCES course(id) ON DELETE CASCADE,
                      title         VARCHAR(300) NOT NULL,
                      description   TEXT,
                      type          VARCHAR(20) NOT NULL DEFAULT 'LAB',
                      status        VARCHAR(20) NOT NULL DEFAULT 'TODO',
                      priority      VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
                      variant       VARCHAR(20),
                      link          TEXT,
                      deadline      TIMESTAMPTZ,
                      submitted_at  TIMESTAMPTZ,
                      points        NUMERIC(5,2),
                      max_points    NUMERIC(5,2),
                      created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                      updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
                      CONSTRAINT task_type_chk      CHECK (type     IN ('LAB','PRACTICE','REPORT','EXAM','OTHER')),
                      CONSTRAINT task_status_chk    CHECK (status   IN ('TODO','IN_PROGRESS','READY','SUBMITTED')),
                      CONSTRAINT task_priority_chk  CHECK (priority IN ('LOW','MEDIUM','HIGH')),
                      CONSTRAINT task_submitted_chk CHECK (submitted_at IS NULL OR status = 'SUBMITTED'),
                      CONSTRAINT task_points_chk    CHECK (
                          (points IS NULL OR points >= 0)
                              AND (max_points IS NULL OR max_points > 0)
                              AND (points IS NULL OR max_points IS NULL OR points <= max_points)
                          )
);

CREATE INDEX idx_course_semester        ON course(semester_id);
CREATE INDEX idx_course_teacher_teacher ON course_teacher(teacher_id);
CREATE INDEX idx_course_link_course     ON course_link(course_id);
CREATE INDEX idx_academic_event_sem     ON academic_event(semester_id);
CREATE INDEX idx_task_course            ON task(course_id);
CREATE INDEX idx_task_deadline_open     ON task(deadline) WHERE status <> 'SUBMITTED';