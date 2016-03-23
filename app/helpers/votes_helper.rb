module VotesHelper
  def split_audit_hashes(input, model)
    values = []
    input.each do |key, value|
      values << split_hash(key, value, model)
    end
    safe_join(values)
  end

  def split_hash(key, value, model)
    val = ''
    case key
    when 'user_id'
      val = split_array(value)
    when 'vote_id'
      val = split_array(value)
    when 'agenda_id'
      val = split_agenda(value)
    when 'presence'
      val = split_presence(value)
    when 'votecode'
      val = split_votecode(value)
    when 'status'
      val = split_status(value)
    when 'title'
      val = split_votecode(value)
    when 'present_users'
      val = split_present_users(value)
    else
      val = value.to_s
    end

    if val.present?
      content = model.human_attribute_name(key) + ': ' + val.to_s
    elsif key == 'reset'
      content = model.human_attribute_name(key)
    end

    content_tag(:p, content)
  end

  def split_votecode(value)
    if value.is_a?(Array) && value.size == 2
      ((value.first.nil? ? t('log.missing') : value.first.to_s) + t('log.to') +
       (value.last.nil? ? t('log.missing') : value.last.to_s))
    else
      value.nil? ? t('log.missing') : value
    end
  end

  def split_array(value)
    unless value.is_a?(Array) && value.first.nil?
      value.to_s
    end
  end

  def split_presence(value)
    if value.is_a?(Array) && value.size == 2 && value.first != value.last
      presence_string(value.last)
    else
      yes_no(value)
    end
  end

  def presence_string(value)
    if value
      t('vote_user.state.present')
    else
      t('vote_user.state.not_present')
    end
  end

  def split_status(value)
    if value.is_a?(Array) && value.size == 2
      vote_status_str(value.first) + t('log.to') + vote_status_str(value.last)
    else
      value.to_s
    end
  end

  def split_agenda(value)
    if value.is_a?(Array) && value.size == 2
      agenda_log_str(value.first) + t('log.to') + agenda_log_str(value.last)
    else
      value.to_s
    end
  end

  def agenda_log_str(value)
    if value.present?
      '§' + Agenda.find(value).order
    else
      t('log.missing')
    end
  end

  def split_present_users(value)
    if value.is_a?(Array) && value.size == 2
      value.first.to_s + t('log.to') + value.last.to_s
    else
      value.to_s
    end
  end

  def vote_state_link(vote, type: nil)
    if vote.present?
      if vote.open?
        link_to(t('vote.do_close'), close_admin_vote_path(vote), method: :patch, class: type)
      elsif vote.closed?
        link_to(t('vote.do_open'), open_admin_vote_path(vote), method: :patch, class: type, data:
                { confirm: t('vote.reopen') })
      else
        link_to(t('vote.do_open'), open_admin_vote_path(vote), method: :patch, class: type)
      end
    end
  end

  def vote_str(votes, id)
    votes.find_by_id(id).to_s
  end

  def vote_option_str(option)
    if option.deleted?
      option.title + t('vote.deleted')
    else
      option.title
    end
  end

  def vote_filter
    [[Audit.human_attribute_name('Vote'), 'Vote'],
     [Audit.human_attribute_name('VoteOption'), 'VoteOption'],
     [Audit.human_attribute_name('VotePost'), 'VotePost']]
  end

  def user_vote_link(vote_status)
    if vote_status.present? && vote_status.vote.present?
      header = user_vote_header(vote_status.vote)
      content = user_vote_post_status(vote_status)

      safe_join([header, content])
    else
      safe_join([fa_icon('exclamation-circle'), ' ', t('vote.no_votes_open')])
    end
  end

  def user_vote_header(vote)
    if vote.present?
      content_tag(:div, class: 'headline') do
        content_tag(:h2) do
          state = vote.open? ? t('vote.open') : t('vote.close')
          safe_join([vote.title, ' ', content_tag(:small, state)])
        end
      end
    end
  end

  def user_vote_post_status(vote_status)
    if vote_status.vote_post.present?
      safe_join([t('vote.already_voted'), ': ', l(vote_status.vote_post.created_at)])
    else
      link_to(t('vote.submit'), new_vote_vote_post_path(vote_status.vote), class: 'btn primary')
    end
  end

  def vote_stats(vote)
    pcount = vote.vote_posts.sum(:selected)
    ocount = vote.vote_options.sum(:count)
    result = "#{pcount} / #{vote.present_users * vote.choices - pcount}"

    if pcount != ocount
      result += t('vote.sum_is_wrong')
    end

    result
  end

  def vote_status_str(state)
    if state.present?
      Vote.human_attribute_name(state)
    else
      t('log.missing')
    end
  end
end
